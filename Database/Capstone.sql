CREATE TABLE IF NOT EXISTS `Users`
(
	`UserID` int NOT NULL AUTO_INCREMENT,
	`FirstName` varchar(50) NOT NULL,
	`LastName` varchar(50) NOT NULL,
	PRIMARY KEY (`UserID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

INSERT INTO `Users` (`FirstName`, `LastName`) VALUES
('Alpha','Aaron'),
('Beta', 'Brian'),
('Charlie', 'Charles');

CREATE TABLE IF NOT EXISTS `Locks`
(
	`LockID` int NOT NULL AUTO_INCREMENT,
	`LockName` varchar(50) NOT NULL,
	PRIMARY KEY (`LockID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

INSERT INTO `Locks` (`LockName`) VALUES
('First Test Lock'),
('Second Test Lock'),
('Third Test Lock');

CREATE TABLE IF NOT EXISTS `Tags`
(
	`TagID` int NOT NULL AUTO_INCREMENT,
	`TagAddress` varchar(17),
	`PhoneID` varchar(5),
	`UserID` int NOT NULL,
	PRIMARY KEY (`TagID`),
	FOREIGN KEY (`UserID`) REFERENCES `Users`(`UserID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

INSERT INTO `Tags` (`TagAddress`, `UserID`) VALUES
('0XADE8C656', '1'),
('0X9EF24FB8', '2');

INSERT INTO `Tags` (`PhoneID`, `UserID`) VALUES
('64', '3');

CREATE TABLE IF NOT EXISTS `TagLocks`
(
	`LockID` int NOT NULL,
	`TagID` int NOT NULL,
	FOREIGN KEY (`LockID`) REFERENCES `Locks`(`LockID`),
	FOREIGN KEY (`TagID`) REFERENCES `Tags`(`TagID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

INSERT INTO `TagLocks` (`LockID`, `TagID`) VALUES
('1', '3'),
('3', '1'),
('2', '2');

CREATE TABLE IF NOT EXISTS `ActivityLog`
(
	`time` DATETIME DEFAULT CURRENT_TIMESTAMP,
	`msg` varchar(200) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

