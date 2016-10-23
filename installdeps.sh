echo "Installing mmoon dependencies..."

function install
{
	echo "* Installing $1..."
	luarocks install --local $1
}

# Add "install <rock>" here
install "lua-cjson"

echo "Done!"
