SHELL := /bin/bash

ec2-deploy:
	rsync -aHv --delete-during --exclude-from rsync_exclude.txt . ec2-training:/home/ec2-user/training/
