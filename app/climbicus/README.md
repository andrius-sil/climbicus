# climbicus

Climbing app for gyms.

## App releases

- Update version in [pubspec.yaml](pubspec.yaml)
- Run `export ENV=stag; make flutter-cross-build`

### Android

- Create a new release in [Google Play Console](https://play.google.com/console/u/0/developers/5343407907611504813/app/4974722539259597079/app-dashboard)
- Upload `build/app/outputs/bundle/release/app-release.aab` to the release


### iOS

- Open `build/ios/archive/Runner.xcarchive` in Xcode
- Open Xcode, select `Runner -> Any iOS Device`
- Click `Distribute App` and follow the steps
- Create `appstorereview` user if it doesn't exist already
