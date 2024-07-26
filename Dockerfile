FROM node:14.21.3-bullseye
# COPY sources.list /etc/apt/sources.list
RUN apt update
RUN apt install -y git
RUN git clone https://github.com/RocketChat/Rocket.Chat.git /rocket
WORKDIR /rocket
RUN curl https://install.meteor.com/ | sh
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN yarn install