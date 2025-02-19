

download_node() {
  echo 'Starting installation...'

  [ -d "$HOME/.nexus" ] && sudo rm -rf "$HOME/.nexus"

  screen -list | grep -q "nexusnode" && screen -S nexusnode -X quit

  sudo apt update -y && sudo apt upgrade -y
  sudo apt-get install -y nano screen cargo build-essential pkg-config libssl-dev git-all protobuf-compiler jq make software-properties-common ca-certificates curl

  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

  source $HOME/.cargo/env
  echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
  source ~/.bashrc
  rustup update

  mkdir -p $HOME/.config/cli

  screen -dmS nexusnode bash -c '
    echo "Beginning script execution in screen session"
    sudo curl https://cli.nexus.xyz/ | sh
    exec bash
  '

  echo 'Node has been started. Go to the screen session. If you want to return to the menu, do NOT EXIT USING CTRL+C. Otherwise, reinstall the node.'
}

go_to_screen() {
  screen -r nexusnode
}

check_logs() {
  screen -S nexusnode -X hardcopy /tmp/screen_log.txt && sleep 0.1 && tail -n 100 /tmp/screen_log.txt && rm /tmp/screen_log.txt
}

try_to_fix() {
  echo "Choose an option:"
  echo "1) First method"
  echo "2) Second method"
  echo "3) Third method"
  read -p "Enter the option number: " choicee

  case $choicee in
    1)
      commands=( "^C" "rustup target add riscv32i-unknown-none-elf" "cd $HOME/.nexus/network-api/clients/cli/" "cargo run --release -- --start --beta" )
      ;;
    2)
      commands=( "^C" "~/.nexus/network-api/clients/cli/target/release/nexus-network --start" )
      ;;
    3)
      commands=( "^C" "cd $HOME/.nexus/network-api/clients/cli/" "rm build.rs" "wget https://raw.githubusercontent.com/londrwus/network-api/refs/heads/main/clients/cli/build.rs" "rustup target add riscv32i-unknown-none-elf" "cd $HOME/.nexus/network-api/clients/cli/" "cargo run --release -- --start --beta" )
      ;;
    *)
      echo "Invalid input. Please choose valid options."
      return
      ;;
  esac

  for cmd in "${commands[@]}"; do
    screen -S "${session}" -p 0 -X stuff "$cmd\n"
    sleep 1
  done
  echo 'Check your logs.'
}

restart_node() {
  echo 'Starting reboot...'

  session="nexusnode"

  if screen -list | grep -q "\.${session}"; then
    screen -S "${session}" -p 0 -X stuff "^C"
    sleep 1
    screen -S "${session}" -p 0 -X stuff "sudo curl https://cli.nexus.xyz/ | sh\n"
    echo "Node has been rebooted."
  else
    echo "Session ${session} not found."
  fi
}

delete_node() {
  screen -S nexusnode -X quit
  sudo rm -r $HOME/.nexus/
  echo 'Node has been deleted.'
}

exit_from_script() {
  exit 0
}

main_menu() {
  channel_logo
  sleep 2
  echo -e "\n\nMenu:"
  echo "1. ??? Install node"
  echo "2. ?? Go to node (exit CTRL+A D)"
  echo "3. ?? View logs"
  echo "4. ?? Try to fix errors"
  echo "5. ?? Restart node"
  echo "6. ? Delete node"
  echo -e "7. ?? Exit script\n"
  read -p "Choose a menu option: " choice

  case $choice in
    1) download_node ;;
    2) go_to_screen ;;
    3) check_logs ;;
    4) try_to_fix ;;
    5) restart_node ;;
    6) delete_node ;;
    7) exit_from_script ;;
    *) echo "Invalid option. Please choose the correct number from the menu." ;;
  esac
}

while true; do
  main_menu
done
