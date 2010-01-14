var current_goal

function show_goal( goal_id ) {
    var link = document.getElementById( 'goal_'+ goal_id +'_link' )
    var goal = document.getElementById( 'goal_'+ goal_id )
    hide_current()
    link.className = "active_goal"
    goal.className = "active_goal"
    current_goal = goal_id
    return false;
}

function hide_current( ) {
    if( ! current_goal ) return false
    var link = document.getElementById( 'goal_'+ current_goal +'_link' )
    var goal = document.getElementById( 'goal_'+ current_goal )
    link.className = ""
    goal.className = "goal"
    return true
}
