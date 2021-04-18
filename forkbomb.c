/*
 * Suicide Docker
 * Copyright (C) 2021  Nikolas Garofil
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

#include <time.h>
#include <getopt.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>
#include <sys/mman.h>

struct settings {
	struct timespec maxtime;
	unsigned long maxnum;
	struct timespec waittime;
	char verbose;
} settings;

volatile unsigned long *pids;

void argtosettings(struct settings *settings, int argc, char **argv) {
	int option;
	struct option options[] = {
		{ "help", no_argument, NULL, 'h' },
		{ "maxtime", required_argument, NULL, 'm' },
		{ "maxnum", required_argument, NULL, 'n' },
		{ "waittime", required_argument, NULL, 'w' },
		{ "verbose", no_argument, NULL, 'v' },
		{ NULL, 0, NULL, 0 }
	};
	unsigned long maxtime, waittime;

	while( (option = getopt_long(argc, argv, "hm:n:w:v", options, NULL)) != -1 ) {
		switch(option) {
			case 'h':
				printf("Runs a forkbomb\n\nOptions:\n");
				printf("--help | -h		Exits after printing this help\n");
				printf("--maxtime | -m MS	Wait MS milliseconds before killing everything (default: %lu)\n", (settings->maxtime).tv_sec * 1000 + (settings->maxtime).tv_nsec / (1000 * 1000));
				printf("--maxnum | -n N		Stop the forkbomb when N processes are running (default: %lu)\n", settings->maxnum);
				printf("--waittime | -w MS	Wait MS milliseconds after every fork (default: %lu)\n", (settings->waittime).tv_sec * 1000 + (settings->waittime).tv_nsec / (1000 * 1000));
				printf("--verbose | -v		Everyone will print info, otherwise only the 1st PID sends the status STDOUT.\n");
				exit(EXIT_SUCCESS);
			case 'm':
				maxtime = strtoul(optarg, NULL, 10);
				(settings->maxtime).tv_sec = (time_t) maxtime / 1000;
				(settings->maxtime).tv_nsec = (maxtime - 1000 * (settings->maxtime).tv_sec) * 1000 * 1000;
				if(errno != 0) { perror("Problem reading maxtime: "); exit(EXIT_FAILURE); }
				if(maxtime == 0 && strcmp(optarg, "0") != 0) { fprintf(stderr, "Non-numerical argument given to -w\n"); exit(EXIT_FAILURE); }
				break;
			case 'n':
				settings->maxnum = strtoul(optarg, NULL, 10);
				if(errno != 0) { perror("Problem reading maxnum: "); exit(EXIT_FAILURE); }
				if(settings->maxnum == 0 && strcmp(optarg, "0") != 0) { fprintf(stderr, "Non-numerical argument given to -w\n"); exit(EXIT_FAILURE); }
				break;
			case 'v':
				settings->verbose = 1;
				break;
			case 'w':
				waittime = strtoul(optarg, NULL, 10);
				(settings->waittime).tv_sec = (time_t) waittime / 1000;
				(settings->waittime).tv_nsec = (waittime - 1000 * (settings->waittime).tv_sec) * 1000 * 1000;
				if(errno != 0) { perror("Problem reading waittime: "); exit(EXIT_FAILURE); }
				if(waittime == 0 && strcmp(optarg, "0") != 0) { fprintf(stderr, "Non-numerical argument given to -w\n"); exit(EXIT_FAILURE); }
				break;
			case '?':
				switch(optopt) {
					case 'm': fprintf(stderr, "No argument given to --maxtime|-m\n"); break;
					case 'n': fprintf(stderr, "No argument given to --maxnum|-n\n"); break;
					case 'w': fprintf(stderr, "No argument given to --waittime|-w\n"); break;
				}
				exit(EXIT_FAILURE);
			default:
				exit(EXIT_FAILURE);
		}
	}
}

void detailedsleep(struct timespec *sleeptime, char verbose, char interruptable) {
	if(interruptable > 0) {
		int stillneedsleep = 1;
		while(stillneedsleep != 0)  { stillneedsleep = clock_nanosleep(CLOCK_REALTIME, 0, sleeptime, sleeptime); }
	} else {
		nanosleep(sleeptime, NULL);
	}
	if(verbose > 0) { printf("PID %lu: There are now %lu pid's and i'm done sleeping.\n", (unsigned long) getpid(), *pids); }
}

/* start a child and return the pid */
pid_t startchild(char verbose) {
	pid_t forkresult = fork();
	if(forkresult == -1) {
		fprintf(stderr, "PID %lu: I can't fork.\n", (unsigned long) getpid());
		exit(EXIT_FAILURE);
	}
	if(forkresult == 0) {	/* child */
		*pids = *pids + 1;	/* only in child code so that the parent and the child don't both increase it */
		if(verbose > 0) {
			printf("PID %lu: I have been created, my parent is %lu and there are now %lu pids.\n", (unsigned long) getpid(), (unsigned long) getppid(), *pids);
		}
	}
	return forkresult;	/* return childpid if parent and 0 if child */
}

/* when receiving SIGUSR1 the head will printout updated info */
void handlesignals(int sig, __attribute__ ((unused)) siginfo_t *info, __attribute__ ((unused)) void *ucontext) {
	switch(sig) {
		case SIGUSR1:
			fprintf(stderr, "PID %lu: At the moment %lu processes have been started. In %lu milliseconds everything will be killed.\n", (unsigned long) getpid(), *pids, settings.maxtime.tv_sec * 1000 + settings.maxtime.tv_nsec / (1000 * 1000));
			break;
		case SIGUSR2:
			if(settings.verbose > 0) { printf("PID %lu: Maximum number of %lu pids reached, killing all of them.\n", (unsigned long) getpid(), *pids); }
			kill(0, SIGTERM);
			break;
		default:
			fprintf(stderr, "PID %lu: Unexpected signal %d received.", (unsigned long) getpid(), sig);
	}
}

int main(int argc, char **argv) {
	volatile void *sharedmem;
	unsigned long parent;

	settings.maxtime.tv_sec = 24 * 60 * 60;
	settings.maxtime.tv_nsec = 0;
	settings.maxnum = 100;
	settings.waittime.tv_sec = 0;
	settings.waittime.tv_nsec = 100 * 1000 * 1000;
	settings.verbose = 0;
	argtosettings(&settings, argc, argv);

	/* 1st proc creates the shared memory */
	sharedmem = mmap(NULL, sizeof(unsigned long), PROT_READ | PROT_WRITE,  MAP_SHARED | MAP_ANONYMOUS, -1, 0);
	if(sharedmem == MAP_FAILED) { perror("Can't allocate shared memory: "); return EXIT_FAILURE;}
	pids = sharedmem;

	*pids = 1;
	parent = (unsigned long) getpid();
	if(startchild(settings.verbose) > 0) {
		/* The parents listens for SIGUSR1 signals */
		struct sigaction new_action;
		new_action.sa_sigaction = handlesignals;
		sigemptyset (&new_action.sa_mask);
		new_action.sa_flags = SA_SIGINFO;
		sigaction (SIGUSR1, &new_action, NULL);

		/* The parent kills everything after maxtime is over, the child will do the forkbomb */
		printf("PID %lu: Starting a sleep of %lu milliseconds after this I will kill all my children.\n", parent, settings.maxtime.tv_sec * 1000 + settings.maxtime.tv_nsec / (1000 * 1000));
		printf("PID %lu: I will also kill all my children once there are %lu of them.\n", parent, settings.maxnum);
		printf("PID %lu: Print current state to STDERR with SIGUSR1 (e.g. 'kill -s SIGUSR1 %lu').\n", parent, parent);
		detailedsleep(&(settings.maxtime), settings.verbose, 1);
		if(settings.verbose > 0) { printf("PID %lu: Maximum time of %lu milliseconds reached, killing all %lu pid's.\n", parent, settings.maxtime.tv_sec * 1000 + settings.maxtime.tv_nsec / (1000 * 1000) , *pids); }
		kill(0, SIGTERM);
	} else {	/* 1st kid creates the forkbomb */
		while(*pids < settings.maxnum) {
			detailedsleep(&(settings.waittime), settings.verbose, 0);
			startchild(settings.verbose);
		}
		if(settings.verbose > 0) { printf("PID %lu: Maximum number of pid's reached, sending SIGUSR2 to %lu.\n", (unsigned long) getpid(), parent); }
		kill(parent, SIGUSR2);	/* mention to parent that maximum number of pid's has been reached */
	}
	return EXIT_SUCCESS;
}
