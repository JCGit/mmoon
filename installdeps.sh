echo "Installing mmoon dependencies..."

function install
{
	echo "* Installing $1..."
	luarocks install --local $1
}

# Add "install <rock>" here

echo "Done!"
