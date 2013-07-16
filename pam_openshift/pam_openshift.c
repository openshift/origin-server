/******************************************************************************
 * A module for Linux-PAM that will set the default security context after login
 * via PAM.
 *
 * Copyright (c) 2012 Red Hat, Inc.
 * Written by Dan Walsh <dwalsh@redhat.com>
 * Additional improvements by Tomas Mraz <tmraz@redhat.com>
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, and the entire permission notice in its entirety,
 *    including the disclaimer of warranties.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote
 *    products derived from this software without specific prior
 *    written permission.
 *
 * ALTERNATIVELY, this product may be distributed under the terms of
 * the GNU Public License, in which case the provisions of the GPL are
 * required INSTEAD OF the above restrictions.  (This clause is
 * necessary due to a potential bad interaction between the GPL and
 * the restrictions contained in a BSD-style copyright.)
 *
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

#include <errno.h>
#include <limits.h>
#include <pwd.h>
#include <grp.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <syslog.h>

#define PAM_SM_AUTH
#define PAM_SM_SESSION

#include <security/pam_modules.h>
#include <security/_pam_macros.h>
#include <security/pam_modutil.h>
#include <security/pam_ext.h>

#include <selinux/selinux.h>
#include <selinux/selinux.h>
#include <selinux/context.h>
#include <selinux/get_default_type.h>

#include <attr/attributes.h>

#ifdef HAVE_LIBAUDIT
#include <libaudit.h>
#include <sys/select.h>
#include <errno.h>
#endif

/* Send audit message */
static

int send_audit_message(pam_handle_t *pamh, int success, security_context_t default_context,
		       security_context_t selected_context)
{
	int rc=0;
#ifdef HAVE_LIBAUDIT
	char *msg = NULL;
	int audit_fd = audit_open();
	security_context_t default_raw=NULL;
	security_context_t selected_raw=NULL;
	rc = -1;
	if (audit_fd < 0) {
		if (errno == EINVAL || errno == EPROTONOSUPPORT ||
                                        errno == EAFNOSUPPORT)
                        return 0; /* No audit support in kernel */
		pam_syslog(pamh, LOG_ERR, "Error connecting to audit system.");
		return rc;
	}
	if (selinux_trans_to_raw_context(default_context, &default_raw) < 0) {
		pam_syslog(pamh, LOG_ERR, "Error translating default context.");
		default_raw = NULL;
	}
	if (selinux_trans_to_raw_context(selected_context, &selected_raw) < 0) {
		pam_syslog(pamh, LOG_ERR, "Error translating selected context.");
		selected_raw = NULL;
	}
	if (asprintf(&msg, "pam: default-context=%s selected-context=%s",
		     default_raw ? default_raw : (default_context ? default_context : "?"),
		     selected_raw ? selected_raw : (selected_context ? selected_context : "?")) < 0) {
		pam_syslog(pamh, LOG_ERR, "Error allocating memory.");
		goto out;
	}
	if (audit_log_user_message(audit_fd, AUDIT_USER_ROLE_CHANGE,
				   msg, NULL, NULL, NULL, success) <= 0) {
		pam_syslog(pamh, LOG_ERR, "Error sending audit message.");
		goto out;
	}
	rc = 0;
      out:
	free(msg);
	freecon(default_raw);
	freecon(selected_raw);
	close(audit_fd);
#else
	pam_syslog(pamh, LOG_NOTICE, "pam: default-context=%s selected-context=%s success %d", default_context, selected_context, success);
#endif
	return rc;
}

static int
send_text (pam_handle_t *pamh, const char *text, int debug)
{
  if (debug)
    pam_syslog(pamh, LOG_NOTICE, "%s", text);
  return pam_info (pamh, "%s", text);
}

static security_context_t user_context=NULL;
static security_context_t prev_user_context=NULL;
static int selinux_enabled=0;

#define UNUSED __attribute__ ((unused))

PAM_EXTERN int
pam_sm_authenticate(pam_handle_t *pamh UNUSED, int flags UNUSED,
		    int argc UNUSED, const char **argv UNUSED)
{
	/* Fail by default. */
	return PAM_AUTH_ERR;
}

PAM_EXTERN int
pam_sm_setcred(pam_handle_t *pamh UNUSED, int flags UNUSED,
	       int argc UNUSED, const char **argv UNUSED)
{
	return PAM_SUCCESS;
}

static void get_mcs_level(int uid, security_context_t *scon) {
        if ((uid < 1) || (uid >523776)) {
          return;
        }
	int SETSIZE = 1023;
	int TIER = SETSIZE;

	int ORD=uid;
	while ( ORD > TIER ) {
		ORD = ORD - TIER;
		TIER -= 1;
	}
	TIER = SETSIZE - TIER;
	ORD = ORD + TIER;
	asprintf(scon, "unconfined_u:system_r:openshift_t:s0:c%d,c%d", TIER, ORD);
}

/* checks if a user is on a list of members of the GID 0 group */
static int is_on_list(char * const *list, const char *member)
{
    while (list && *list) {
        if (strcmp(*list, member) == 0)
            return 1;
        list++;
    }
    return 0;
}

static int openshift_domain(pam_handle_t *pamh, struct passwd *pw) {
	struct group *grp;
        security_context_t secontext;
        context_t parsed_context;
        char * comp_context = "openshift_var_lib_t";
        int selength;
        int cmpval=0;

	if (!pw->pw_uid) return 0;

        if (strlen(pw->pw_dir)!=0) {
          selength = getfilecon(pw->pw_dir, & secontext);
          if ( selength > 0) {
            parsed_context = context_new(secontext);
            cmpval = strcmp(context_type_get(parsed_context), comp_context);
            context_free(parsed_context);
            freecon(secontext);
          } else {
            return 0;
          }
          if (cmpval != 0) {
            return 0;
          }
        } else {
          return 0;
        }

	if ((grp = pam_modutil_getgrnam (pamh, "wheel")) == NULL) {
	    grp = pam_modutil_getgrgid (pamh, 0);
	} 
	if (!grp) return 1;
	if (pw->pw_gid == grp->gr_gid) return 0;
	if (!grp->gr_mem) return 1;
	return ! is_on_list(grp->gr_mem, pw->pw_name);
}

PAM_EXTERN int
pam_sm_open_session(pam_handle_t *pamh, int flags UNUSED,
		    int argc, const char **argv)
{
	int i, debug = 0;
	int verbose=0, close_session=0;
	int ret = 0;
	const char *username;
	const void *void_username;
	struct passwd *pw;
	
	/* Parse arguments. */
	for (i = 0; i < argc; i++) {
		if (strcmp(argv[i], "debug") == 0) {
			debug = 1;
		}
		if (strcmp(argv[i], "verbose") == 0) {
			verbose = 1;
		}
		if (strcmp(argv[i], "close") == 0) {
			close_session = 1;
		}
	}
	
	if (debug)
		pam_syslog(pamh, LOG_NOTICE, "Open Session");
	
	/* this module is only supposed to execute close_session */
	if (close_session)
		return PAM_SUCCESS;

	if (!(selinux_enabled = is_selinux_enabled()>0) )
		return PAM_SUCCESS;
	
	if (pam_get_item(pamh, PAM_USER, &void_username) != PAM_SUCCESS ||
	    void_username == NULL) {
		return PAM_USER_UNKNOWN;
	}
	username = void_username;
	
	pw = pam_modutil_getpwnam( pamh, username );
	if (!pw) {
		pam_syslog(pamh, LOG_ERR, "Unable to find uid for user %s", username);
		return -1;
	}

	if (openshift_domain(pamh, pw)) {
		get_mcs_level(pw->pw_uid, &user_context);
	} else {
		user_context = strdup("unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023");
	}
	if (!user_context) {
		pam_syslog(pamh, LOG_ERR, "Unable to generate User context for user %s: %s", username, strerror(errno));
		return -1;
	}
	
	if (getexeccon(&prev_user_context)<0) {
		prev_user_context=NULL;
	}
	send_audit_message(pamh, 1, user_context, user_context);
	ret = setexeccon(user_context);
	if (ret==0 && verbose) {
		char msg[PATH_MAX];
		snprintf(msg, sizeof(msg),
			 "Security Context %s Assigned", user_context);
		send_text(pamh, msg, debug);
	}
	if (ret) {
		pam_syslog(pamh, LOG_ERR,
			   "Error!  Unable to set %s executable context %s. %s",
			   username, user_context, strerror(errno));
		if (security_getenforce() == 1) {
			freecon(user_context);
			return PAM_AUTH_ERR;
		}
	} else {
		if (debug)
			pam_syslog(pamh, LOG_NOTICE, "set %s security context to %s",
				   username, user_context);
	}
	
	freecon(user_context);
	
	return PAM_SUCCESS;
}

PAM_EXTERN int
pam_sm_close_session(pam_handle_t *pamh, int flags UNUSED,
		     int argc, const char **argv)
{
	int i, debug = 0, status = PAM_SUCCESS, open_session = 0;
	if (! (selinux_enabled ))
		return PAM_SUCCESS;
	
	/* Parse arguments. */
	for (i = 0; i < argc; i++) {
		if (strcmp(argv[i], "debug") == 0) {
			debug = 1;
		}
		if (strcmp(argv[i], "open") == 0) {
			open_session = 1;
		}
	}
	
	if (debug)
		pam_syslog(pamh, LOG_NOTICE, "Close Session");
	
	if (open_session)
		return PAM_SUCCESS;
	
	if (setexeccon(prev_user_context)) {
		pam_syslog(pamh, LOG_ERR, "Unable to restore executable context %s: %s",
			   prev_user_context ? prev_user_context : "", strerror(errno));
		if (security_getenforce() == 1)
			status = PAM_AUTH_ERR;
		else
			status = PAM_SUCCESS;
	} else if (debug)
		pam_syslog(pamh, LOG_NOTICE, "Executable context back to original");
	
	if (prev_user_context) {
		freecon(prev_user_context);
		prev_user_context = NULL;
	}
	
	return status;
}
