-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Aug 19, 2025 at 06:39 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `user_chatbot_db`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `insert_student_with_activation` (IN `p_email` VARCHAR(255), IN `p_fname` VARCHAR(255), IN `p_lname` VARCHAR(255), IN `p_hashed_password` VARCHAR(255), IN `p_hashed_token` CHAR(64))   BEGIN
    -- Exit handler to rollback transaction on any SQL exception
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
    END;

    -- Begin atomic transaction
    START TRANSACTION;

    -- Insert student record into 'students' table
    INSERT INTO students (email, fname, lname, password)
    VALUES (p_email, p_fname, p_lname, p_hashed_password);

    -- Insert activation record into 'student_account_activation' table
    -- 'is_active' defaults to FALSE
    -- 'token_sent' is set to current timestamp using NOW()
    INSERT INTO student_account_activation (email, token, token_sent)
    VALUES (p_email, p_hashed_token, NOW());

    -- Commit transaction if both inserts succeed
    COMMIT;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `students`
--

CREATE TABLE `students` (
  `email` varchar(255) NOT NULL,
  `fname` varchar(100) NOT NULL,
  `lname` varchar(100) NOT NULL,
  `password` varchar(65) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `students`
--

INSERT INTO `students` (`email`, `fname`, `lname`, `password`) VALUES
('ROBERTOJJAMES@students.utech.edu.jm', 'Roberto', 'James', '$2b$12$e1Tk.8PFlvCPw6qd3RDMmePt5pTGLy7Qa0qC8ngCEQ.ArrNtxz1Ei');

-- --------------------------------------------------------

--
-- Table structure for table `student_account_activation`
--

CREATE TABLE `student_account_activation` (
  `email` varchar(255) NOT NULL,
  `token` char(64) DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 0,
  `account_creation` datetime DEFAULT current_timestamp(),
  `token_sent` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `student_account_activation`
--

INSERT INTO `student_account_activation` (`email`, `token`, `is_active`, `account_creation`, `token_sent`) VALUES
('ROBERTOJJAMES@students.utech.edu.jm', '$2b$12$Av8i6fev2lB8Chqmgbi2fefT.KOAMOo92OU6/O4TX2I.Tk9GN3Un.', 1, '2025-08-18 22:06:36', '2025-08-18 22:50:46');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `students`
--
ALTER TABLE `students`
  ADD PRIMARY KEY (`email`);

--
-- Indexes for table `student_account_activation`
--
ALTER TABLE `student_account_activation`
  ADD PRIMARY KEY (`email`),
  ADD UNIQUE KEY `token` (`token`);

--
-- Constraints for dumped tables
--

--
-- Constraints for table `student_account_activation`
--
ALTER TABLE `student_account_activation`
  ADD CONSTRAINT `student_account_activation_ibfk_1` FOREIGN KEY (`email`) REFERENCES `students` (`email`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
