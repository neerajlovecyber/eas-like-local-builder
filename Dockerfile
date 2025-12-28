FROM ubuntu:24.04

# Set environment variables for Java
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH=$PATH:$JAVA_HOME/bin

# Install essential packages, Java 17, and curl
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    unzip \
    build-essential \
    openjdk-17-jdk \
    software-properties-common \
    git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 20.19.4
RUN wget https://nodejs.org/dist/v20.19.4/node-v20.19.4-linux-x64.tar.xz \
    && tar -xJf node-v20.19.4-linux-x64.tar.xz -C /usr/local --strip-components=1 \
    && rm node-v20.19.4-linux-x64.tar.xz

# Install specific versions of npm, Yarn, pnpm, node-gyp, and eas-cli
RUN npm install -g npm@10.9.3 \
    && npm install -g yarn@1.22.22 pnpm@10.14.0 node-gyp@11.3.0 eas-cli@latest

# Install Bun 1.2.20
ENV BUN_INSTALL=/usr/local
RUN curl -fsSL https://bun.sh/install | bash -s "bun-v1.2.20"

# Install Android NDK r27b with robust retry logic
RUN wget --tries=20 --retry-connrefused --waitretry=5 --timeout=60 --no-dns-cache https://dl.google.com/android/repository/android-ndk-r27b-linux.zip \
    && unzip android-ndk-r27b-linux.zip -d /opt \
    && rm android-ndk-r27b-linux.zip

ENV NDK_HOME=/opt/android-ndk-r27b

# Install Android SDK command-line tools
# Using a newer version compatible with modern environments (11076708 corresponds to build-tools 13.0)
RUN wget --tries=20 --retry-connrefused --waitretry=5 --timeout=60 --no-dns-cache https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip \
    && mkdir -p /opt/android-sdk/cmdline-tools \
    && unzip commandlinetools-linux-11076708_latest.zip -d /opt/android-sdk/cmdline-tools \
    && mv /opt/android-sdk/cmdline-tools/cmdline-tools /opt/android-sdk/cmdline-tools/latest \
    && rm commandlinetools-linux-11076708_latest.zip

# Set environment variables for Android SDK
ENV ANDROID_HOME=/opt/android-sdk
ENV PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools

# Install required Android SDK components
RUN yes | sdkmanager --licenses \
    && sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

# Hardcode the EAS build command with a default profile
CMD ["bash", "-c", "eas build --platform android --local --profile ${PROFILE:-development}"]