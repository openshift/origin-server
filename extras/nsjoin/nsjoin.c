#include <errno.h>
#include <limits.h>
#include <pwd.h>
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
#include <selinux/context.h>
#include <selinux/get_default_type.h>

#include <sys/types.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <pwd.h>

#include <libvirt/libvirt.h>
#include <pthread.h>

#ifdef HAVE_LIBAUDIT
#include <libaudit.h>
#include <sys/select.h>
#include <errno.h>
#endif

#include <pwd.h>
#include <syslog.h>
#include <cap-ng.h>
#include <pty.h>

#define VIR_ALLOC(ptr) virAlloc(&(ptr), sizeof(*(ptr)))
#define VIR_FREE(ptr) virFree((void *) (1 ? (const void *) &(ptr) : (ptr)))

static int nfdlist = 0;
static int *fdlist = NULL;
static virDomainPtr  dom = NULL;
static virConnectPtr conn = NULL;

void fini(void) {
    int i;
    if (nfdlist > 0) {
        for (i = 0 ; i < nfdlist ; i++)
            close(fdlist[i]);
        VIR_FREE(fdlist);
        nfdlist = 0;
    }
    if (conn) {
        virConnectClose(conn); conn = NULL;
    }
    if (dom) {
        virDomainFree(dom); dom = NULL;
    }
}

static int
lxcEnterNamespace(const char *name, struct passwd *pw)
{
    virSecurityLabelPtr seclabel = NULL;
    int ret = PAM_AUTH_ERR;
    pid_t pid;
    size_t i;
    conn = virConnectOpen("lxc:///");
    if (!conn) {
        syslog(LOG_ERR, "Unable to connect to lxc:///");
        return ret;
    }

    dom = virDomainLookupByName (conn, name);
    if (!dom) {
        syslog(LOG_ERR, "Container %s does not exist", name);
        goto err;
    }

    if ((nfdlist = virDomainLxcOpenNamespace(dom, &fdlist, 0)) < 0) {
        syslog(LOG_ERR, "Can not open %s namespace", name);
        goto err;
    }

    if (is_selinux_enabled() > 0) {
        if (VIR_ALLOC(seclabel) < 0) {
            syslog(LOG_ERR, "Out of memory");
            goto err;
        }

        if (virDomainGetSecurityLabel(dom, seclabel) < 0) {
            syslog(LOG_ERR, "Can not security context for %s namespace", name);
            goto err;
        }

        ret = setexeccon(seclabel->label);
        if (ret < 0) {
            syslog(LOG_ERR, "Can not setexeccon(%s) for %s namespace", seclabel->label, name);
            goto err;
        }
    }
    ret = 0;
    goto cleanup;

err:
    fini();
cleanup:
    VIR_FREE(seclabel);
    return ret;
}

static capng_select_t cap_set = CAPNG_SELECT_CAPS;

/**
 * This function will drop all capabilities.
 */
static int drop_caps(struct passwd *pw)
{
	if (capng_have_capabilities(cap_set) == CAPNG_NONE)
		return 0;
	capng_setpid(getpid());
	capng_clear(cap_set);
	setresgid(pw->pw_gid, pw->pw_gid, pw->pw_gid);
	setresuid(pw->pw_uid, pw->pw_uid, pw->pw_uid);
	return capng_apply(CAPNG_SELECT_CAPS);
}

main(int argc, char **argv) {
        struct passwd *pw;
	pid_t cpid;
	pid_t ccpid;
	int status;
	int status2;
  uid_t uid = getuid();
  int optOffset = 1;
  
  if (argc > 1) {
      if (uid != 0) {
          fprintf(stderr, "Root is required to select a container to join");
          return -1;
      }
      //printf("%s\n", argv[1]);
      pw = getpwnam(argv[1]);
      optOffset++;
  } else {
      pw = getpwuid(getuid());
  }
  if (!pw) {
      perror(argv[0]);
      return -1;
  }
  
  //if(uid == 0){
  //  clearenv();
  //  setenv("HOME", pw->pw_dir, 1);
  //  setenv("USER", pw->pw_name, 1);
  //  setenv("GEAR_BASE_DIR", "/var/lib/openshift", 1);
  //  setenv("OPENSHIFT_GEAR_UUID", pw->pw_name, 1);
  //  setenv("PATH", ":/bin:/usr/local/bin:/usr/bin", 1);
  //  setenv("LANG", "en_US.UTF-8", 1);
  //}
  
  if (lxcEnterNamespace(pw->pw_name, pw)) 
      return -1;
            
	cpid = fork();
	if(cpid == 0 ) {
		/* Fork once because we don't want to affect
		 * virsh's namespace itself
		 */
		if (setreuid(0,0) < 0)
			perror("setresuid");
		
		if (nfdlist > 0) {
			if (virDomainLxcEnterNamespace(dom,
						       nfdlist,
						       fdlist,
						       NULL,
						       NULL,
						       0) < 0)
				_exit(255);
		}
		
		drop_caps(pw);
		
    ccpid = fork();
    if(ccpid == 0){
      chdir(pw->pw_dir);
      
      if(argc <= optOffset){
        //char* args[] = {"/bin/bash", "--login", "-c", "/usr/bin/oo-trap-user.rb", NULL};
        //char* args[] = {"/bin/bash", "--login", NULL};
        char* args[] = {"/usr/bin/oo-trap-user", NULL};
		    if (execv(args[0], args) < 0) 
		  	  perror("Oops");
		  }else{
        char* args[] = {"/bin/bash", "--login", "-c", argv[optOffset], NULL};
		    if (execv("/bin/bash", args) < 0) 
		  	  perror("Oops");
		  }
      _exit(-1);
	  }
	  wait(&status2);
  	  _exit(WEXITSTATUS(status2));
	}
	wait(&status);
	exit(WEXITSTATUS(status));
}
