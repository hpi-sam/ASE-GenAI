let
  pkgs = import ../nixpkgs {};
in pkgs.mkShell {
  buildInputs = with pkgs; [
    python312
    python312Packages.scikit-learn
    python312Packages.pandas
    python312Packages.numpy
    python312Packages.matplotlib
    python312Packages.seaborn
    python312Packages.openai
    python312Packages.ollama
    python312Packages.python-dotenv
  ];
}

