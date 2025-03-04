#Use official image
FROM nginx:latest

#Copy custom web page
COPY index.html /usr/share/nginx/html


#Export Port 80
EXPOSE 80

#Start Nginx
CMD ["nginx", "-g", "daemon off;"]