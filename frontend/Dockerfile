# Flutter Web — Production Build
# Stage 1: Build the Flutter web app
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Copy pubspec files first for dependency caching
# (build context is repo root per railway.toml, so prefix with frontend/)
COPY frontend/pubspec.yaml frontend/pubspec.lock ./
RUN flutter pub get

# Copy the rest of the source
COPY frontend/ .

# BASE_URL is injected by Railway as a build argument.
# Set it in Railway → frontend service → Variables as BASE_URL=https://your-backend.railway.app
ARG BASE_URL=http://localhost:3000

# Build Flutter web with CanvasKit renderer for consistent rendering
RUN flutter build web --release \
    --dart-define=BASE_URL=$BASE_URL

# Stage 2: Serve with nginx
FROM nginx:alpine AS production

# Remove default nginx static assets
RUN rm -rf /usr/share/nginx/html/*

# Copy built Flutter app
COPY --from=build /app/build/web /usr/share/nginx/html

# Copy nginx config
COPY frontend/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
