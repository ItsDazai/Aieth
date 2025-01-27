# Step 1: Use Node.js 20 as the base image
FROM node:20-slim as build

# Step 2: Set the working directory
WORKDIR /app

# Step 3: Copy package-related files and install dependencies
COPY package.json package-lock.json /app/
RUN npm install

# Step 4: Ensure permissions and use npx for Vite build
COPY . /app/
RUN chmod +x ./node_modules/.bin/vite && npx vite build

# Step 5: Use nginx for production
FROM nginx:alpine as production
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
