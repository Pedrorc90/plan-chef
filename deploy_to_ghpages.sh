#!/bin/bash
# Deploy Flutter web build to GitHub Pages (docs folder)

# Build the Flutter web app
flutter build web --base-href "/plan-chef/"

# Copy build output to docs folder
cp -r build/web/* docs/

# Add, commit, and push changes
git add docs
git commit -m "Add web build"
git push
