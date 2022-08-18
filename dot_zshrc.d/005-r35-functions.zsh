function update-goenv() {
  echo -e "\033[32m==>\033[0m Updating GoEnv";
  cd ${GOENV_ROOT:-$HOME/.goenv} \
    && git pull \
    && cd -
  echo ""
  echo "✅ Done!"
}

