include ../Makefile

ec2-update-security-group-rules: check-env
	./ec2_update_security_group_rules.sh

flutter-apk-install: check-env
	cd ../app/climbicus/; flutter build apk -t lib/main_${ENV}.dart --split-per-abi; flutter install

# Workarounds for
# - https://issuetracker.google.com/issues/158753935
# - https://github.com/flutter/flutter/issues/65334
flutter-apk-install-hack: check-env
	cd ../app/climbicus/; flutter build apk --debug -t lib/main_${ENV}.dart --split-per-abi --no-shrink; flutter build apk --profile -t lib/main_${ENV}.dart --split-per-abi --no-shrink; flutter build apk -t lib/main_${ENV}.dart --split-per-abi --no-shrink; flutter install

flutter-appbundle-build: check-env
	cd ../app/climbicus/; flutter build appbundle -t lib/main_${ENV}.dart

flutter-code-gen:
	cd ../app/climbicus/; flutter pub run build_runner build

flutter-launcher-icons:
	cd ../app/climbicus/; flutter pub run flutter_launcher_icons:main

flutter-key-gen:
	${JAVA_BIN}/keytool -genkey -v -keystore key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key

flutter-logs:
	cd ../app/climbicus/; flutter logs

