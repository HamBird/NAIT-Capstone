<?php
    error_log(json_encode("________________________________________________________________________"));
    
    // on run, set connection to null, response to empty, and status to false, call SQLConnect(); to connect to database
    $connection = null;
    $response = "";
    $status = false;
    $ip = "localhost";
    header('Access-Control-Allow-Origin: *');
    SQLConnect();
    //phpinfo();
    //********************************************************************************************
    //Method: function SQLConnect()
    //Purpose: attempts to connect to database, and if it can't, return an error
    //Parameters: none
    //Returns: none
    //*********************************************************************************************
    function SQLConnect() {
        global $connection, $response, $ip;

        $connection = new mysqli($ip, "nrojas1_user", "B9KFDliKo66m", "nrojas1_Capstone");

        if($connection->connect_error) {
            $response = "Connection Error {" . $connection->connect_errno . "} " . $connection->connect_error;
            echo json_encode($response);
            error_log(json_encode($response));
            die();
        }
        else {
            error_log("Connection successfully established!");
        }
    }
    //********************************************************************************************
    //Method: function SQLQuery($query)
    //Purpose: grabs the query and determines if it can connect to database and returns the data
    //Parameters: $query - the query to be checked and run
    //Returns: $result - the result of the query search
    //*********************************************************************************************
    function SQLQuery($query) {
        global $connection, $response;

        $result = false;

        if($connection == null) {
            $response = "No database connection established!";
            return $result;
        }
    
        if(!($result = $connection->query($query))) {
            $response = "Query Error: {$connection->errno} : {$connection->error}!";
        }
        
        return $result;
    }
    //********************************************************************************************
    //Method: function MySQLNonQuery($query)
    //Purpose: grabs the query and determines if it can connect to database and returns the data
    //Parameters: $query - the query to be checked and run
    //Returns: $connection - the affected rows
    // $result - the result if the query is successful
    //*********************************************************************************************
    function MySQLNonQuery($query) {
        global $connection, $response;

        $result = 0;
        if($connection == null)
        {
            $response = "No database connection made";
            return $result;
        }

        if(!($result = $connection -> query($query)))
        {
            $response = "Query Error: {$connection->errno} : {$connection->error}";
            return $result;
        }
        return $connection->affected_rows;
    }
    // Inserts Activity data to database
    function InsertActivity($message) {
        global $connection, $response;
        
        $message = trim(strip_tags($connection->real_escape_string($message)));
        
        $query = "INSERT INTO `ActivityLog` (`msg`)";
        $query .= " VALUES ('$message');"; 

        error_log(json_encode($query));
        if(!($numrows = mySQLNonQuery( $query ))) {
            echo $response;
        }
    
        return $numrows;
    }
    // Fetches all tags and phoneids for specific tagID
    function QueryTags($filter) {
        global $connection, $response;

        $filter = trim(strip_tags($connection -> real_escape_string($filter)));

        $query = "SELECT TagAddress, PhoneID";
        $query .= " FROM Tags";
        $query .= " INNER JOIN TagLocks ON TagLocks.TagID = Tags.TagID";
        $query .= " INNER JOIN Locks ON Locks.LockID = TagLocks.LockID";
        $query .= " WHERE Locks.LockID LIKE $filter";

        $output = null;

        if($results = SQLQuery($query)) {
            $output = $results->fetch_all();
        }
        else {
            return $response;
        }
    
        return $output;
    }
    function getusers()
    {
        global $connection, $response;

        $query = "SELECT *";
        $query .= " FROM Users";
        $output = null;

        if($results = SQLQuery($query)) {
            $output = $results->fetch_all();
        }
        else {
            return $response;
        }
    
        return $output;
    }
    // Fetches all names related to a specific card or phone
    function RetrieveName($filter, $type) {
        global $connection, $response;

        $filter = trim(strip_tags($connection -> real_escape_string($filter)));

        $query = "";
        if ($type == "Tag") {
            $query = "SELECT Users.FirstName, Users.LastName";
            $query .= " FROM Tags";
            $query .= " INNER JOIN Users ON Tags.UserID = Users.UserID";
            $query .= " WHERE Tags.TagAddress like '$filter'";
        }
        else {
            $query = "SELECT Users.FirstName, Users.LastName";
            $query .= " FROM Tags";
            $query .= " INNER JOIN Users ON Tags.UserID = Users.UserID";
            $query .= " WHERE Tags.PhoneID like '$filter'";
        }

        error_log($query);
        $output = null;

        if($results = SQLQuery($query)) {
            $output = $results->fetch_all();
        }
        else {
            return $response;
        }
    
        return $output;
    }
    function RetrieveActivity() {
        global $connection, $response;

        $query = "SELECT *";
        $query .= " FROM ActivityLog";
        $query .= " ORDER BY ActivityLog.time desc";
        
        $output = null;
        if($results = SQLQuery($query)) {
            $output = $results->fetch_all();
        }
        else {
            return $response;
        }
        return $output;
    }
    // This block of queries below to remove a user from the database
    /*
    ___________________________________________________________________________________________________________________________________________________
    */
    function DeleteUser($fname, $lname) {
        global $connection, $response;
        
        $fname = trim(strip_tags($connection->real_escape_string($fname)));
        $lname = trim(strip_tags($connection->real_escape_string($lname)));
        
        $query = "DELETE Users FROM Users WHERE Users.FirstName LIKE '$fname' AND Users.LastName LIKE '$lname'";

        error_log(json_encode($query));
        if(!($numrows = mySQLNonQuery( $query ))) {
            echo $response;
        }
    
        return $numrows;
    }
    function DeleteTag($fname, $lname) {
        global $connection, $response;
        
        $fname = trim(strip_tags($connection->real_escape_string($fname)));
        $lname = trim(strip_tags($connection->real_escape_string($lname)));
        
        $query = "DELETE Tags FROM Tags INNER JOIN Users ON Users.UserID = Tags.UserID";
        $query .= " WHERE Users.FirstName LIKE '$fname' AND Users.LastName LIKE '$lname'";

        error_log(json_encode($query));
        if(!($numrows = mySQLNonQuery( $query ))) {
            echo $response;
        }
    
        return $numrows;
    }
    function DeleteTagLock($fname, $lname) {
        global $connection, $response;
        
        $fname = trim(strip_tags($connection->real_escape_string($fname)));
        $lname = trim(strip_tags($connection->real_escape_string($lname)));
        
        //$query = "DELETE Tags FROM Tags INNER JOIN Users ON Users.UserID = Tags.UserID"
        //$query .= " WHERE Users.FirstName LIKE '$fname' AND Users.LastName LIKE '$lname'"
        $query = "DELETE TagLocks FROM TagLocks INNER JOIN Tags ON Tags.TagID = TagLocks.TagID";
        $query .= " INNER JOIN Users ON Users.UserID = Tags.UserID";
        $query .= " WHERE Users.FirstName LIKE '$fname' AND Users.LastName LIKE '$lname'";


        error_log(json_encode($query));
        if(!($numrows = mySQLNonQuery( $query ))) {
            echo $response;
        }
    
        return $numrows;
    }
    /*
    ________________________________________________________________________________________________________________________________________
    */
    // Retrieves all lock names
    function GetLockNames() {
        global $connection, $response;

        $query = "SELECT Locks.LockName";
        $query .= " FROM Locks";
        
        $output = null;
        if($results = SQLQuery($query)) {
            $output = $results->fetch_all();
        }
        else {
            return $response;
        }
        return $output;
    }
    // The code below is for Adding/Removing Tags or Phones
    function RetrieveUserID($fname, $lname) {
        global $connection, $response;
        
        $fname = trim(strip_tags($connection->real_escape_string($fname)));
        $lname = trim(strip_tags($connection->real_escape_string($lname)));

        $query = "SELECT Users.UserID FROM Users WHERE Users.FirstName LIKE '$fname' AND Users.LastName LIKE '$lname'";

        $output = null;
        if($results = SQLQuery($query)) {
            $output = $results->fetch_all();
        }
        else {
            return $response;
        }
        return $output;
    }
    // This function can be used to see if the user already has a tag or doesnt have one
    function TagCheck($userid) {
        global $connection, $response;
        
        $userid = trim(strip_tags($connection->real_escape_string($userid)));
        
        //$query = "DELETE Tags FROM Tags INNER JOIN Users ON Users.UserID = Tags.UserID"
        $query = "SELECT * FROM Tags WHERE Tags.UserID = '$userid'";

        $output = null;
        if($results = SQLQuery($query)) {
            $output = $results->fetch_all();
        }
        else {
            return $response;
        }
        return $output;
    }
    function RetrieveLockID($lockname) {
        global $connection, $response;
        
        $lockname = trim(strip_tags($connection->real_escape_string($lockname)));

        $query = "SELECT Locks.LockID FROM Locks WHERE Locks.LockName LIKE '$lockname'";

        $output = null;
        if($results = SQLQuery($query)) {
            $output = $results->fetch_all();
        }
        else {
            return $response;
        }
        return $output;
    }

    // This needs to be changed into an update query rather than an insert query
    // Since if there is a remove query of similar nature, it will delete the entire table
    function AddTag($tagid, $address, $type) {
        global $connection, $response;

        $tagid = trim(strip_tags($connection->real_escape_string($tagid)));
        $address = trim(strip_tags($connection->real_escape_string($address)));
        $type = trim(strip_tags($connection->real_escape_string($type)));

        $query = "";
        if ($type == "Tag") {
            $query = "UPDATE Tags SET Tags.TagAddress = '$address'";
            $query .= " WHERE Tags.TagID LIKE '$tagid'";
        }
        else {
            $query = "UPDATE Tags SET Tags.PhoneID = '$address'";
            $query .= " WHERE Tags.TagID LIKE '$tagid'";
        }

        error_log(json_encode($query));
        if(!($numrows = mySQLNonQuery( $query ))) {
            echo $response;
        }
    
        return $numrows;
    }
    function RemoveTag($userid, $type) {
        global $connection, $response;

        $userid = trim(strip_tags($connection->real_escape_string($userid)));
        $type = trim(strip_tags($connection->real_escape_string($type)));

        $query = "";
        if ($type == "Tag") {
            $query = "UPDATE Tags SET Tags.TagAddress = NULL";
            $query .= " WHERE Tags.UserID LIKE '$userid'";
        }
        else {
            $query = "UPDATE Tags SET Tags.PhoneID = NULL";
            $query .= " WHERE Tags.UserID LIKE '$userid'";
        }

        error_log(json_encode($query));
        if(!($numrows = mySQLNonQuery( $query ))) {
            echo $response;
        }
        error_log(json_encode($numrows));
        return $numrows;
    }
    function AddTagLocks($tagid, $lockid) {
        global $connection, $response;

        $tagid = trim(strip_tags($connection->real_escape_string($tagid)));
        $lockid = trim(strip_tags($connection->real_escape_string($lockid)));

        $query = "INSERT INTO `TagLocks` (`LockID`, `TagID`)";
        $query .= " VALUES ('$lockid', '$tagid')";

        error_log(json_encode($query));
        if(!($numrows = mySQLNonQuery( $query ))) {
            echo $response;
        }
    
        return $numrows;
    }
    function CheckTagLocks($tagid, $lockid) {
        global $connection, $response;

        $tagid = trim(strip_tags($connection->real_escape_string($tagid)));
        $lockid = trim(strip_tags($connection->real_escape_string($lockid)));

        $query = "SELECT * FROM TagLocks WHERE TagLocks.LockID LIKE '$lockid' AND TagLocks.TagID LIKE '$tagid'";

        error_log(json_encode($query));
        if(!($numrows = mySQLNonQuery( $query ))) {
            echo $response;
        }
        
        error_log(json_encode($numrows));
        return $numrows;
    }
    /*
    function AddTag($tagid) {
        global $connection, $response;
        
        $tagid = trim(strip_tags($connection->real_escape_string($tagid)));
    }*/
    // Adds new user to database
    function put_users($fn, $ln)
    {
        global $connection, $response;

        $query = "INSERT INTO Users (firstname, lastname) VALUES ('$fn', '$ln')";
        if($results = SQLQuery($query))
        {
            return "successfully added user";
        }
        else
        {
            return "Error adding user";
        }
    }
    // this is used to accompany 'put_users' so there is something to modify
    function AddEmptyTag($userid) {
        global $connection, $response;

        $userid = trim(strip_tags($connection->real_escape_string($userid)));

        $query = "INSERT INTO `Tags` (`UserID`)";
        $query .= " VALUES ('$userid')";

        if(!($numrows = mySQLNonQuery( $query ))) {
            echo $response;
        }
        return $numrows;
    }
    // _____________________________________________________________
    function RetrieveTagID($userid) {
        global $connection, $response;
        
        $userid = trim(strip_tags($connection->real_escape_string($userid)));

        $query = "SELECT Tags.TagID FROM Tags WHERE Tags.UserID LIKE '$userid'";

        $output = null;
        if($results = SQLQuery($query)) {
            $output = $results->fetch_all();
        }
        else {
            return $response;
        }
        return $output;
    }
    function CheckLock($lockname) {
        global $connection, $response;

        $lockname = trim(strip_tags($connection->real_escape_string($lockname)));

        $query = "SELECT * FROM Locks WHERE Locks.LockName LIKE '$lockname'";

        if(!($numrows = mySQLNonQuery( $query ))) {
            echo $response;
        }
        return $numrows;
    }
    function AddLock($lockname) {
        global $connection, $response;

        $lockname = trim(strip_tags($connection->real_escape_string($lockname)));

        $query = "INSERT INTO `Locks` (`LockName`)";
        $query .= " VALUES ('$lockname')";

        if(!($numrows = mySQLNonQuery( $query ))) {
            echo $response;
        }
        return $numrows;
    }
    function CheckUser($fname, $lname) {
        global $connection, $response;

        $fname = trim(strip_tags($connection->real_escape_string($fname)));
        $lname = trim(strip_tags($connection->real_escape_string($lname)));

        $query = "SELECT * FROM Users WHERE Users.FirstName Like '$fname' AND Users.LastName LIKE '$lname'";

        if(!($numrows = mySQLNonQuery( $query ))) {
            echo $response;
        }
        return $numrows;
    }
    // Need to Add a TagLock if doesn't exist for user and lock before updating tag information
    //  cant add taglock when adding new user however
    error_log(json_encode($_GET));

    //Test Query for App Grabbing users
    if(isset($_GET['getUsers'])){
        $response = getusers();
        error_log(json_encode($response));
        header('Content-Type: application/json');
        echo json_encode($response);
    }
    // Retrieves POST data from POST input
    $post_data = json_decode(file_get_contents('php://input'), true); // Get the POST data
    error_log(json_encode($post_data));

    //error_log(json_encode($post_data['AddUser']));
    //Test for APP adding users
    if(isset($post_data['AddUser']))
    {
        error_log('Post Detected');
        $data = $post_data;
        $clean_firstname = trim(strip_tags($data['firstName']));
        $clean_lastname = trim(strip_tags($data['lastName']));

        $rows = CheckUser($clean_firstname, $clean_lastname);

        header('Content-Type: application/json');
        if($rows < 1) {
            $response = put_users($clean_firstname, $clean_lastname);

            $userid = RetrieveUserID($clean_firstname, $clean_lastname);
            
            AddEmptyTag($userid[0][0]);
            //echo json_encode($response);
            //echo json_encode("You got nothing, you lose!");
            echo json_encode("Successfully added!");
        }
        echo json_encode("Could not be added!");
        //echo json_encode("You got nothing, you lose!");
    }
    else if(isset($post_data['remove'])) {
        error_log("Delete Tag");

        $names = explode(" ",$post_data['name']);
        $userid = RetrieveUserID($names[0], $names[1]);
        
        $lockid = RetrieveLockID($post_data['lock']);
        
        $tagid = RetrieveTagID($userid[0][0]);

        error_log(json_encode($userid));
        error_log(json_encode($lockid));
        error_log(json_encode($tagid));

        $rows = CheckTagLocks($tagid[0][0], $lockid[0][0]);
        if($rows > 0) {
            RemoveTag($userid[0][0], $post_data['type']);

            echo json_encode("Removed tag");
        }

        echo json_encode("Did not remove!");
    }
    // Adding a tag
    else if(isset($post_data['add'])) {
        error_log("Add Tag");

        $names = explode(" ",$post_data['name']);
        $userid = RetrieveUserID($names[0], $names[1]);
        
        $lockid = RetrieveLockID($post_data['lock']);
        
        $tagid = RetrieveTagID($userid[0][0]);

        error_log(json_encode($userid));
        error_log(json_encode($lockid));
        error_log(json_encode($tagid));

        $rows = CheckTagLocks($tagid[0][0], $lockid[0][0]);
        if($rows < 1) {
            AddTagLocks($tagid[0][0], $lockid[0][0]);
            //echo json_encode("Removed tag");
        }

        $responsedata['tagid'] = $tagid[0][0];
        $responsedata['lockid'] = $lockid[0][0];

        echo json_encode($responsedata);
    }
    // Used to test add user on the test server
    else if(isset($_POST['remove']))
    {
        error_log("Delete Tag");

        $names = explode(" ",$_POST['name']);
        $userid = RetrieveUserID($names[0], $names[1]);
        
        $lockid = RetrieveLockID($_POST['lock']);
        
        $tagid = RetrieveTagID($userid[0][0]);

        error_log(json_encode($userid));
        error_log(json_encode($lockid));
        error_log(json_encode($tagid));

        $rows = CheckTagLocks($tagid[0][0], $lockid[0][0]);

        if($rows > 0) {
            RemoveTag($userid[0][0], $_POST['type']);

            echo json_encode("Removed tag");
        }

        echo json_encode("Did not remove!");
    }
    else if(isset($post_data['name'])) {
        error_log("Inside Removing Check!");
        $names = explode(" ",$post_data['name']);
        error_log(json_encode($names));

        DeleteTagLock($names[0], $names[1]);
        DeleteTag($names[0], $names[1]);
        DeleteUser($names[0], $names[1]);

        $response = "Successful";
        header('Content-Type: application/json');
        echo json_encode($response);
    }
    else if(isset($_GET['Active'])) {
        $response = RetrieveActivity();
        error_log(json_encode("Entered Activity"));
        header('Content-Type: application/json');
        echo json_encode($response);
    }
    else if(isset($_GET['LockNames'])) {
        $response = GetLockNames();
        error_log(json_encode("Entered Lock Names"));
        header('Content-Type: application/json');
        echo json_encode($response);
    }
    // For Pico's GET request to gather data of users for the lock id
    else if (isset($_GET['Locks'])) {
        // Handle GET request
        // Assuming you want to return some data, you can retrieve it from a database or any other source
        // Here, we'll just return a sample response
        $data["Locks"] = QueryTags($_GET['Locks']);
        //$response = array("message" => "This is a GET request response", "data" => $data);
        $response = $data;
        header('Content-Type: application/json');
        // echo "Heres No Locks";

        echo json_encode($response);
    }
    else if (isset($post_data['TagData'])) {
        $data = $post_data['TagData'];

        header('Content-Type: application/json');
        AddTag($data[0], $data[1], $data[2]);

        echo json_encode("Successful Insertion");
    }
    // For PICO's POST request to push activity data to database
    else if (isset($post_data['AddLock'])) {
        $lockname = $post_data['lock'];

        header('Content-Type: application/json');

        $rows = CheckLock($lockname);

        if($rows < 1) {
            AddLock($lockname);
            echo json_encode("Insert Successful");
        }
        echo json_encode("Insert Unsuccessful");
    }
    else if (isset($post_data['Activity'])) {
    //else if (isset($_POST['Activity'])) {
        // Handle POST request
        // Assuming you want to process the data sent by the MicroPython device
        // Here, we'll just echo back the received data
        $data = $post_data['Activity']; // Get the POST data
        header('Content-Type: application/json');
        if ($data) {
            error_log("Data Received");
            error_log(json_encode($data));
            $lockid = $data[0];
            $tagmsg = "";

            if ($data[1] != 0) { 
                $tagmsg = ", Tag Used: " . $data[1]; 
                $names = RetrieveName($data[1], "Tag");
                $tagmsg .= ", User: " . $names[0][0] . " " . $names[0][1];
            }
            elseif ($data[2] != 0) { 
                $tagmsg = ", Phone Used: " . $data[2]; 
                $names = RetrieveName($data[2], "");
                $tagmsg .= ", User: " . $names[0][0] . " " . $names[0][1];


            }
            elseif ($data[3] != 0) { 
                $tagmsg = ", Master Used: " . $data[3]; 
            }

            $msg = "Lock ID Accessed: $lockid" . $tagmsg;
            if (InsertActivity($msg) > 0) {
                echo json_encode(array("Success" => "ACtivity Posted"));
            }
            echo json_encode(array("error" => "Activity Not Posted"));

        } else {
            error_log("Data Refused");
        }
    } 
    // If Neither GET or POST catches work, print error back
?>
