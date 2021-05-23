include ../Makefile

IP_ADDR = $(shell ipconfig getifaddr en0)

ec2-update-security-group-rules: check-env
	./ec2_update_security_group_rules.sh

db-backup: check-env
	./db_backup.sh

flutter-apk-install: check-env
	cd ../app/climbicus/; flutter build apk --dart-define=ENV=${ENV} --dart-define=DEV_HOST_IP=http://${IP_ADDR}:5000 --split-per-abi; flutter install

flutter-ios-install: check-env
	cd ../app/climbicus/; flutter build ios --dart-define=ENV=${ENV} --dart-define=DEV_HOST_IP=http://${IP_ADDR}:5000; flutter install

flutter-appbundle-build: check-env
	cd ../app/climbicus/; flutter build appbundle --dart-define=ENV=${ENV}

flutter-ipa-build: check-env
	cd ../app/climbicus/; flutter build ipa --dart-define=ENV=${ENV}

flutter-cross-build: flutter-appbundle-build flutter-ipa-build

flutter-code-gen:
	cd ../app/climbicus/; flutter pub run build_runner build --delete-conflicting-outputs

flutter-launcher-icons:
	cd ../app/climbicus/; flutter pub run flutter_launcher_icons:main

flutter-key-gen:
	${JAVA_BIN}/keytool -genkey -v -keystore key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key

flutter-logs:
	cd ../app/climbicus/; flutter logs

