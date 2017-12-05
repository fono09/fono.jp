TARGET_DIR=$1
ln -s /var/www/fono.jp.back/photos ./static/photos
hugo-gallery static/photos/$TARGET_DIR "photo/$TARGET_DIR" $TARGET_DIR 'https://fono.jp/'
rm ./static/photos
hugo
