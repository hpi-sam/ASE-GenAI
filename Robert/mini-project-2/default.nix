let
  pkgs = import ../nixpkgs {};
in pkgs.mkShell {
  buildInputs = with pkgs; [
    docker-compose
    nodejs_22
  ];

  shellHook = ''
    runBackend() {
      tmux new-session -d -s dbbackend -c $(pwd)
      tmux send 'newgrp docker' ENTER # For some reason this is required
      tmux send 'docker-compose up --build' ENTER
    }

    killBackend() {
      tmux send-keys -t dbbackend C-c
      # It takes up to 10.2s for Docker to shut down their containers.
      sleep 15
      tmux kill-session -t dbbackend
    }

    help() {
      echo ""
      echo "🚀 Welcome to the producers shell 🚀"
      echo ""
      echo "Be aware, you need to be in the /src dir of the repository outside a tmux session."
      echo "Following commands are available:"
      echo "   - runBackend: Start the backend services in the 'dbbackend' tmux session."
      echo "   - killBackend: Cancels processes and kills 'dbbackend' tmux session."
      echo "   - help: Display this help message."
    }

    if [ "$TERM_PROGRAM" = "tmux" ]; then
      echo "Cannot run tmux scripts in tmux session."
      echo "Exiting ..."
      exit
    else
      curr_dir=$(basename $(pwd))
      if [ ! "$curr_dir" = "src" ]; then
        cd src
      fi
      help
    fi
  '';
}

