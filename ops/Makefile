include ../Makefile

ec2-update-security-group-rules: check-env
	./ec2_update_security_group_rules.sh

flutter-apk-install: check-env
	cd ../app/climbicus/; flutter build apk -t lib/main_${ENV}.dart --split-per-abi; flutter install

flutter-code-gen:
	cd ../app/climbicus/; flutter pub run build_runner build

