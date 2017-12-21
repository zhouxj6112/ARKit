rm -rf ARHome
mkdir ARHome
mkdir ARHome/Payload
cp -r ARHome.app ARHome/Payload/ARHome.app
cp Icon.png ARHome/iTunesArtwork
cd ARHome
zip -r ARHome.ipa Payload iTunesArtwork

exit 0