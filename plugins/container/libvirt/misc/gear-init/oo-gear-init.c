#include <unistd.h>
#include <stdio.h>
#include <errno.h>
#include <signal.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

int run;

void shandler(int signo)
{
  int status;
  
  switch(signo){
    case SIGCHLD:
    {
      if (wait(&status) == -1){
        perror("Wait error");      
      }
      signal(SIGCHLD, shandler);
      break;
    }
    case SIGTERM:
    case SIGHUP:    
    {
      run = 0;
      break;
    }
  }
}

int main(int argc, char *argv[])
{
  int cpid;
  FILE *fp;
  
  signal(SIGCHLD, shandler);
  signal(SIGTERM, shandler);
  signal(SIGHUP, shandler); 

  cpid = fork();
  if(0 == cpid){
    char container_id[1024];
    memset(container_id, 0, sizeof(container_id));
    
    fp = fopen("/dev/container-id", "r");
    if (fp == NULL){
      perror("container id");
      _exit(-1);
    }
    
    fgets(container_id, 1023, fp);
    fclose(fp);
    
    char* args[] = {"/usr/bin/oo-su", container_id, "--command", "\"/usr/bin/gear start\"", NULL};
    if (execv(args[0], args) < 0)
      perror("Oops");
    _exit(0);
  }
  
  run = 1;
  while(run)
    pause();
  return 0;
}
