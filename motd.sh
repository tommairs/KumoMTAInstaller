echo "Running:"
sudo /opt/kumomta/sbin/kumod -V
cat /etc/os-release |grep -Po '(?<=PRETTY_NAME\=")[^["]*'
echo
