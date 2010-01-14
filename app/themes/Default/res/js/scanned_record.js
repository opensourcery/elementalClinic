function confirmInvalid() {
    var confirming = confirm( "Are you sure you want to mark this file as invalid? This will move the file out of the list of available files. \n\nOnly do this for files that are unreadable." );
    if( confirming ) {
        return true;
    }
    return false;
}

function confirmWrongClient() {
    var confirming = confirm( "Are you sure this is the wrong patient for the file? \n\nIf you continue, the description will be lost and the file will return to the unassociated scanned records queue." );
    if( confirming ) {
        return true;
    }
    return false;
}
