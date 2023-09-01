* ===========================================================================
* Run all certification tests
* ===========================================================================

	cls
	do setup // clean up sandbox folder, reinstall require, etc.,
	
	
	do test-debug // run "require, debug(...)" to ensure we can extract versions from already-extracted strings
	do test-simple // run simple "require package>=1.2.3"
	do test-requirements // "require using requirements.txt" ; require
	do test-install
	do test-list
	do test-adopaths // alternative adopaths
	
	do test-packagesearch
	do test-groundtruth // exhaustive list of cases

exit
