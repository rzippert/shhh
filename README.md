# shhh

Very simple, quickly hacked GUI for a video and audio tracks noise remover script.
Uses ffmpeg filters and rnnoise.
Expect bugs, but works fine for basic usage.
Interface muito simples, improvisada, para aplicar filtros de redução de ruído em vídeo e áudio.
Usa `ffmpeg` (requisito) e `rnnoise` (fornecido com o app).

![Screenshot from 2021-08-24 20-02-17](https://user-images.githubusercontent.com/2091971/130701015-b70e5f2f-fee4-497c-8f0b-9732ca64e482.png)


# references
This software uses a compiled binary of https://github.com/cpuimage/rnnoise.

# installation
Basta usar o pacote .deb para instalar em distros Debian-like. Procurar depois por **shhh** nos aplicativos.

# build
Use o script build.sh. Necessário instalar o [fpm](https://github.com/jordansissel/fpm).
