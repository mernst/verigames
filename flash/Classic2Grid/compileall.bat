python classic2grid.py input\Application output\Application
python classic2grid.py input\Application1 output\Application1
python classic2grid.py input\Connection output\Connection
python classic2grid.py input\DemoWorld output\DemoWorld
python classic2grid.py input\Scribble output\Scribble
python classic2grid.py input\Server output\Server
python classic2grid.py input\Storage output\Storage
python classic2grid.py input\UserData output\UserData
python classic2grid.py input\Vulture output\Vulture
python layoutgrid.py output\ApplicationLayout output\ApplicationLayout -o
python layoutgrid.py output\Application1Layout output\Application1Layout -o
python layoutgrid.py output\ConnectionLayout output\ConnectionLayout -o
python layoutgrid.py output\DemoWorldLayout output\DemoWorldLayout -o
python layoutgrid.py output\ScribbleLayout output\ScribbleLayout -o
python layoutgrid.py output\ServerLayout output\ServerLayout -o
python layoutgrid.py output\StorageLayout output\StorageLayout -o
python layoutgrid.py output\UserDataLayout output\UserDataLayout -o
python layoutgrid.py output\VultureLayout output\VultureLayout -o
cd output
7z a ApplicationLayout.zip ApplicationLayout.xml
7z a ApplicationConstraints.zip ApplicationConstraints.xml
7z a Application1Layout.zip Application1Layout.xml
7z a Application1Constraints.zip Application1Constraints.xml
7z a ConnectionLayout.zip ConnectionLayout.xml
7z a ConnectionConstraints.zip ConnectionConstraints.xml
7z a DemoWorldLayout.zip DemoWorldLayout.xml
7z a DemoWorldConstraints.zip DemoWorldConstraints.xml
7z a ScribbleLayout.zip ScribbleLayout.xml
7z a ScribbleConstraints.zip ScribbleConstraints.xml
7z a ServerLayout.zip ServerLayout.xml
7z a ServerConstraints.zip ServerConstraints.xml
7z a StorageLayout.zip StorageLayout.xml
7z a StorageConstraints.zip StorageConstraints.xml
7z a UserDataLayout.zip UserDataLayout.xml
7z a UserDataConstraints.zip UserDataConstraints.xml
7z a VultureLayout.zip VultureLayout.xml
7z a VultureConstraints.zip VultureConstraints.xml
cd ..