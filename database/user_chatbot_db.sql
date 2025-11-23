-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Nov 23, 2025 at 04:17 AM
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
    INSERT INTO student (email, fname, lname, password)
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
-- Table structure for table `chat_history`
--

CREATE TABLE `chat_history` (
  `message_id` bigint(20) NOT NULL,
  `conversation_id` bigint(20) NOT NULL,
  `role` enum('user','AI') NOT NULL,
  `message` text NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `chat_history`
--

INSERT INTO `chat_history` (`message_id`, `conversation_id`, `role`, `message`, `created_at`) VALUES
(1, 14, 'user', 'hello tell me the names of all the deans and HOS', '2025-11-22 19:39:08'),
(2, 14, 'AI', 'Here are the Deans and Heads of School at UTECH Jamaica:\n\n**Deans:**\n\n*   **President:** Dr. Kevin Brown\n*   **COLLEGE OF BUSINESS AND MANAGEMENT (COBAM):** Olubusola Akinladejo (Actg.)\n*   **COLLEGE OF HEALTH SCIENCES (COHS):** Dr. Adella Campbell\n*   **FACULTY OF THE BUILT ENVIRONMENT (FOBE):** Dr. Laurence Neufville\n*   **FACULTY OF EDUCATION AND LIBERAL STUDIES (FELS):** Dr. Harold McDermott\n*   **FACULTY OF LAW (FOLW):** Marcia Robinson (Actg.)\n*   **FACULTY OF ENGINEERING AND COMPUTING (FENC):** Prof. Sean Thorpe\n*   **FACULTY OF SCIENCE AND SPORT (FOSS):** Prof. Samson Omoregie\n\n**Heads of School (HOS):**\n\n*   **COLLEGE OF BUSINESS AND MANAGEMENT (COBAM):**\n    *   SOBA: Celia McKoy\n    *   SHTM (Actg.): Dr. Noreen Brown Roomes\n    *   JDSEEL (Actg.): Prince Graham-Haynes\n*   **COLLEGE OF HEALTH SCIENCES (COHS):**\n    *   Caribbean School of Nursing (Actg.): Anthonette Patterson-Bartley\n    *   Pharmacy: Dr. Lisa Bromfield\n    *   Allied Health and Wellness: Vanessa White-Barrow\n*   **FACULTY OF THE BUILT ENVIRONMENT (FOBE):**\n    *   SBLM: Anetheo Jackson\n    *   CSA: Jacquiann Lawton\n*   **FACULTY OF EDUCATION AND LIBERAL STUDIES (FELS):**\n    *   SOTAVE: Dr. Junior Martin\n    *   Humanities and Social Sciences: Dr. Clover Jones McKenzie\n*   **FACULTY OF ENGINEERING AND COMPUTING (FENC):**\n    *   SOE: Dr. Shallon Stubbs\n    *   SCIT: Dr. David White\n*   **FACULTY OF SCIENCE AND SPORT (FOSS):**\n    *   CSOSS (Actg.): Dr. Melissa Sanderson\n    *   SOMAS: Ave Maria McIntosh\n    *   FOSS (Actg.): Dr. Nikki Bramwell', '2025-11-22 19:39:08'),
(3, 14, 'user', 'what was the last question i asked?', '2025-11-23 01:38:41'),
(4, 14, 'AI', 'I\'m here to assist with questions about UTech Jamaica. For topics outside the university, I recommend consulting another source.', '2025-11-23 01:38:41'),
(5, 14, 'user', 'so you do not remember my last question?', '2025-11-23 01:39:43'),
(6, 14, 'AI', 'I can see our conversation history, including your last question: \"what was the last question i asked?\". My previous response was to clarify that my primary function is to assist with questions specifically about UTech Jamaica.\n\nHow can I help you with information about the university today?', '2025-11-23 01:39:43'),
(7, 14, 'user', 'hello', '2025-11-23 03:11:35'),
(8, 14, 'AI', 'Hello! How can I assist you with information about UTech Jamaica today?', '2025-11-23 03:11:35'),
(9, 14, 'user', 'what was the previous question i asked', '2025-11-23 03:12:04'),
(10, 14, 'AI', 'You asked: \"hello tell me the names of all the deans and HOS\".', '2025-11-23 03:12:04'),
(11, 15, 'user', 'hello what what are all the faculties on campus', '2025-11-23 03:14:29'),
(12, 15, 'AI', 'The University of Technology, Jamaica has several Colleges and Faculties. Here they are:\n\n*   **College of Business & Management (COBAM)**\n*   **College of Health Sciences (COHS)**\n*   **Faculty of Education & Liberal Studies (FELS)**\n*   **Faculty of Engineering & Computing (FENC)**\n*   **Faculty of Law (FOLW)**\n*   **Faculty of Science and Sport (FOSS)**\n*   **Faculty of the Built Environment (FOBE)**\n*   **Joint Colleges of Medicine, Oral Health and Veterinary Sciences** (this entity comprises the College of Medicine, College of Oral Health Sciences, and College of Veterinary Sciences).', '2025-11-23 03:14:29');

-- --------------------------------------------------------

--
-- Table structure for table `conversation`
--

CREATE TABLE `conversation` (
  `conversation_id` bigint(20) NOT NULL,
  `token_UUID` char(36) NOT NULL,
  `email` varchar(255) NOT NULL,
  `started_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `conversation`
--

INSERT INTO `conversation` (`conversation_id`, `token_UUID`, `email`, `started_at`, `deleted_at`) VALUES
(14, '563b8d81-01ea-4d5b-8b09-3f4f5cbdb620', 'john.doe@students.utech.edu.jm', '2025-11-22 19:39:08', NULL),
(15, '0095b7c4-bce9-41f1-80f6-8a431e7cc243', 'john.doe@students.utech.edu.jm', '2025-11-23 03:14:29', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `student`
--

CREATE TABLE `student` (
  `email` varchar(255) NOT NULL,
  `fname` varchar(100) NOT NULL,
  `lname` varchar(100) NOT NULL,
  `password` varchar(65) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `student`
--

INSERT INTO `student` (`email`, `fname`, `lname`, `password`) VALUES
('john.doe@students.utech.edu.jm', 'John', 'Doe', '$2b$12$/lRYFyjKIr3yxX8AEWktVuKiEFUALGqbcFNKtb9X6pi0wZyjmV2P.');

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
('john.doe@students.utech.edu.jm', '$2b$12$CoVz/JXAz11k16O1yU4tXuj3Sw6lJICnQNRK/f9Pc3ucm3pC9Qqdi', 1, '2025-11-22 14:37:50', '2025-11-22 14:37:50');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `chat_history`
--
ALTER TABLE `chat_history`
  ADD PRIMARY KEY (`message_id`),
  ADD KEY `conversation_id` (`conversation_id`);

--
-- Indexes for table `conversation`
--
ALTER TABLE `conversation`
  ADD PRIMARY KEY (`conversation_id`),
  ADD UNIQUE KEY `token_UUID` (`token_UUID`),
  ADD KEY `email` (`email`);

--
-- Indexes for table `student`
--
ALTER TABLE `student`
  ADD PRIMARY KEY (`email`);

--
-- Indexes for table `student_account_activation`
--
ALTER TABLE `student_account_activation`
  ADD PRIMARY KEY (`email`),
  ADD UNIQUE KEY `token` (`token`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `chat_history`
--
ALTER TABLE `chat_history`
  MODIFY `message_id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT for table `conversation`
--
ALTER TABLE `conversation`
  MODIFY `conversation_id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `chat_history`
--
ALTER TABLE `chat_history`
  ADD CONSTRAINT `chat_history_ibfk_1` FOREIGN KEY (`conversation_id`) REFERENCES `conversation` (`conversation_id`);

--
-- Constraints for table `conversation`
--
ALTER TABLE `conversation`
  ADD CONSTRAINT `conversation_ibfk_1` FOREIGN KEY (`email`) REFERENCES `student` (`email`);

--
-- Constraints for table `student_account_activation`
--
ALTER TABLE `student_account_activation`
  ADD CONSTRAINT `student_account_activation_ibfk_1` FOREIGN KEY (`email`) REFERENCES `student` (`email`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
