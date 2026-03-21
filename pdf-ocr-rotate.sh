#!/bin/bash

# Nom de l'outil
NAME="pdf-ocr-rotate"

# Couleurs pour le terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Fonction de vérification/installation des paquets
check_dep() {
    if ! rpm -q "$1" &> /dev/null; then
        echo -e "${RED}[!] Dépendance manquante : $1${NC}"
        read -p "Voulez-vous installer $1 maintenant ? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo dnf install -y "$1"
        else
            echo "Erreur : $1 est requis pour continuer."
            exit 1
        fi
    fi
}

# --- 1. Vérification des dépendances ---
echo -e "${GREEN}[*] Vérification de l'environnement Fedora...${NC}"
check_dep "ocrmypdf"
check_dep "tesseract-langpack-fra"
check_dep "tesseract-osd"

# --- 2. Vérification des arguments ---
if [ "$#" -ne 2 ]; then
    echo "Usage: $NAME <fichier_entree.pdf> <fichier_sortie.pdf>"
    exit 1
fi

INPUT="$1"
OUTPUT="$2"

if [ ! -f "$INPUT" ]; then
    echo -e "${RED}Erreur : Le fichier '$INPUT' n'existe pas.${NC}"
    exit 1
fi

# --- 3. Exécution ---
echo -e "${GREEN}[*] Traitement OCR et Rotation automatique en cours...${NC}"
echo "Cible : $INPUT -> $OUTPUT"

# On utilise le seuil à 0 pour forcer la rotation si le texte est détecté de travers
ocrmypdf --rotate-pages --rotate-pages-threshold 0 -l fra "$INPUT" "$OUTPUT"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}[V] Terminé avec succès !${NC}"
    echo "Fichier généré : $OUTPUT"
else
    echo -e "${RED}[X] Une erreur est survenue lors du traitement.${NC}"
    exit 1
fi
