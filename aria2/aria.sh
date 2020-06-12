 docker run  -d --name ariang \
  -p 8123:80 \
  -p 4434:443 \
  -p 6800:6800 \
  -e PUID=0 \
  -e PGID=0 \
  -v /root/.config/filebrowser/filebrowser.db:/app/filebrowser.db \
  -v /root/usb_data/Download:/data \
  -v /root/.config/aria2:/app/conf \
  wahyd4/aria2-ui:arm32
