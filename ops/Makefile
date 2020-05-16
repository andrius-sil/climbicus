include ../Makefile

ec2-update-security-group-rules: check-env
	./ec2_update_security_group_rules.sh

flutter-apk-install: check-env
	cd ../app/climbicus/; flutter build apk -t lib/main_${ENV}.dart --split-per-abi; flutter install

flutter-appbundle-build: check-env
	cd ../app/climbicus/; flutter build appbundle -t lib/main_${ENV}.dart

flutter-code-gen:
	cd ../app/climbicus/; flutter pub run build_runner build

flutter-key-gen:
	${JAVA_BIN}/keytool -genkey -v -keystore key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key

