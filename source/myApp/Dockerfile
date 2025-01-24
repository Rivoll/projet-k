FROM nginx:alpine

# Étape 2 : Copier ton site web (les fichiers HTML) dans le répertoire de Nginx
COPY ./src/html /usr/share/nginx/html

# Exposer le port 80 (le port par défaut de Nginx)
EXPOSE 80

# Étape 3 : Démarrer Nginx au lancement du container
CMD ["nginx", "-g", "daemon off;"]# Étape 2 : Copier ton site web (les fichiers HTML) dans le répertoire de Nginx
COPY ./html /usr/share/nginx/html

# Exposer le port 80 (le port par défaut de Nginx)
EXPOSE 80

# Étape 3 : Démarrer Nginx au lancement du container
CMD ["nginx", "-g", "daemon off;"]