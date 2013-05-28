#!/bin/sh

if [ -e ../notes.git/config ]; then
  echo "It appears you already have set up"
  exit 1
fi

echo "setting up..."

cd ..  # basedir
mkdir notes notes.git

# Prepare notes.git
cd notes.git
git --bare init
git config core.bare false
git config core.worktree ../notes
git config receive.denycurrentbranch ignore

# Arrange hook for post-receive event
if [ ! -e hooks/post-receive ]; then
  echo "#!/bin/sh" > hooks/post-receive
fi
cat >> hooks/post-receive <<EOF

# Bitter
git checkout -f
touch ../engine/reindex-needed
EOF
chmod +x hooks/post-receive

# Copy default files
cd ..  # basedir
cp -R engine/default/. notes/

# Commit them
cd notes.git
git add .
git commit -m "Setup"

echo "\nsetup completed"
