# Use an official Elixir runtime as a parent image
FROM elixir:1.17

# Install basic packages
RUN apt-get update
RUN apt-get install -y postgresql-client ncurses-dev imagemagick libc-dev openssh-server git gcc inotify-tools

# Install hex package manager
RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix archive.install hex phx_new 1.6.6 --force

# Create code directory
RUN mkdir /code

COPY entrypoint.sh .

RUN ["chmod", "+x", "/entrypoint.sh"]

WORKDIR /code

CMD ["/entrypoint.sh"]
