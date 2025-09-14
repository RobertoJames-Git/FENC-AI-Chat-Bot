-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Sep 14, 2025 at 02:59 AM
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
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `chat_history`
--

INSERT INTO `chat_history` (`message_id`, `conversation_id`, `role`, `message`, `created_at`, `deleted_at`) VALUES
(1, 1, 'user', 'n', '2025-09-13 20:07:05', NULL),
(2, 1, 'AI', 'I\'m here to assist with questions about UTech Jamaica. For topics outside the university, I recommend consulting another source.', '2025-09-13 20:07:05', NULL),
(3, 2, 'user', 'hello', '2025-09-13 20:16:29', NULL),
(4, 2, 'AI', 'Hello! I\'m your UTECH Jamaica chat assistant. How may I help you today?', '2025-09-13 20:16:29', NULL),
(5, 3, 'user', 'hello', '2025-09-13 20:21:22', NULL),
(6, 3, 'AI', 'Hello! Welcome to UTECH Jamaica. How can I assist you today?', '2025-09-13 20:21:22', NULL),
(7, 4, 'user', 'what is your name', '2025-09-13 20:26:44', NULL),
(8, 4, 'AI', 'I\'m here to assist with questions about UTech Jamaica. For topics outside the university, I recommend consulting another source.', '2025-09-13 20:26:44', NULL),
(9, 5, 'user', 'heelo', '2025-09-13 20:35:38', NULL),
(10, 5, 'AI', 'Hello! How can I help you today?', '2025-09-13 20:35:38', NULL),
(11, 6, 'user', 'hello', '2025-09-14 00:45:03', NULL),
(12, 6, 'AI', 'Hello! Welcome to UTECH Jamaica. How can I assist you today?', '2025-09-14 00:45:03', NULL),
(13, 6, 'user', 'who is the president', '2025-09-14 00:45:33', NULL),
(14, 6, 'AI', 'The President of UTECH Jamaica is Dr. Kevin Brown.', '2025-09-14 00:45:33', NULL),
(15, 6, 'user', 'name all faculties and school and Head of Schools and Deans at utech', '2025-09-14 00:46:53', NULL),
(16, 6, 'AI', 'Here are the Faculties, Schools, Deans, and Heads of Schools at UTECH Jamaica:\n\n**COLLEGE OF BUSINESS AND MANAGEMENT (COBAM)**\n*   **Dean (Actg.):** Olubusola Akinladejo\n*   **Schools & Head of Schools:**\n    *   School of Business Administration (SOBA): Celia McKoy\n    *   School of Hospitality and Tourism Management (SHTM) (Actg.): Dr. Noreen Brown Roomes\n    *   School of Entrepreneurship, Engineering and Logistics (JDSEEL) (Actg.): Prince Graham-Haynes\n\n**COLLEGE OF HEALTH SCIENCES (COHS)**\n*   **Dean:** Dr. Adella Campbell\n*   **Schools & Head of Schools:**\n    *   Caribbean School of Nursing (Actg.): Anthonette Patterson-Bartley\n    *   School of Pharmacy: Dr. Lisa Bromfield\n    *   School of Allied Health and Wellness: Vanessa White-Barrow\n\n**FACULTY OF THE BUILT ENVIRONMENT (FOBE)**\n*   **Dean:** Dr. Laurence Neufville\n*   **Schools & Head of Schools:**\n    *   School of Building and Land Management (SBLM): Anetheo Jackson\n    *   School of Architecture and the Caribbean School of Architecture (CSA): Jacquiann Lawton\n\n**FACULTY OF EDUCATION AND LIBERAL STUDIES (FELS)**\n*   **Dean:** Dr. Harold McDermott\n*   **Schools & Head of Schools:**\n    *   School of Technical and Vocational Education (SOTAVE): Dr. Junior Martin\n    *   School of Humanities and Social Sciences: Dr. Clover Jones McKenzie\n\n**FACULTY OF LAW (FOLW)**\n*   **Dean (Actg.):** Marcia Robinson\n\n**FACULTY OF ENGINEERING AND COMPUTING (FENC)**\n*   **Dean:** Prof. Sean Thorpe\n*   **Schools & Head of Schools:**\n    *   School of Engineering (SOE): Dr. Shallon Stubbs\n    *   School of Computing and Information Technology (SCIT): Dr. David White\n\n**FACULTY OF SCIENCE AND SPORT (FOSS)**\n*   **Dean:** Prof. Samson Omoregie\n*   **Schools & Head of Schools:**\n    *   Caribbean School of Sport Sciences (CSOSS) (Actg.): Dr. Melissa Sanderson\n    *   School of Mathematics and Statistics (SOMAS): Ave Maria McIntosh\n    *   School of Natural and Applied Sciences (Actg.): Dr. Nikki Bramwell', '2025-09-14 00:46:53', NULL),
(17, 6, 'user', 'what are their contact details', '2025-09-14 00:49:39', NULL),
(18, 6, 'AI', 'Here are the contact details for the Faculties, Schools, Deans, and Heads of Schools at UTECH Jamaica. Please remember to add the area code **876** before each telephone number.\n\n**COLLEGE OF BUSINESS AND MANAGEMENT (COBAM)**\n*   **Dean (Actg.):** Olubusola Akinladejo\n    *   Contact: 970-5140\n*   **School of Business Administration (SOBA):** Celia McKoy\n    *   Contact: 970-5369\n    *   Student Affairs Assistants (SOBA): 970-5110 / 5126 / 5108\n*   **School of Hospitality and Tourism Management (SHTM) (Actg.):** Dr. Noreen Brown Roomes\n    *   Contact: 970-5430\n    *   Student Affairs Assistants (SHTM): 970-5431 / 5433-4\n*   **Joan Duncan School of Entrepreneurship, Engineering and Logistics (JDSEEL) (Actg.):** Prince Graham-Haynes\n    *   Contact: 970-5623\n    *   Student Affairs Assistants (JDSEEL): 970-5623\n\n**COLLEGE OF HEALTH SCIENCES (COHS)**\n*   **Dean:** Dr. Adella Campbell\n    *   Contact: 970-5317 / 927-1680 ext. 3470\n*   **Caribbean School of Nursing (Actg.):** Anthonette Patterson-Bartley\n    *   Contact: 927-1680 ext. 3778\n*   **School of Pharmacy:** Dr. Lisa Bromfield\n    *   Contact: 927-1680 ext. 3787\n*   **School of Allied Health and Wellness:** Vanessa White-Barrow\n    *   Contact: 970-5850\n*   **Student Affairs Assistant (General COHS):** 970-5314 / 927-1680 ext. 3795\n\n**FACULTY OF THE BUILT ENVIRONMENT (FOBE)**\n*   **Dean:** Dr. Laurence Neufville\n    *   Contact: 970-5257 / 56\n*   **School of Building and Land Management (SBLM):** Anetheo Jackson\n    *   Contact: 970-5333 / 5\n*   **School of Architecture and the Caribbean School of Architecture (CSA):** Jacquiann Lawton\n    *   Contact: 970-5355-7\n*   **Student Affairs Assistant (General FOBE):** 970-5335 / 5355\n\n**FACULTY OF EDUCATION AND LIBERAL STUDIES (FELS)**\n*   **Dean:** Dr. Harold McDermott\n    *   Contact: 927-1612 / 970-5419-20\n*   **School of Technical and Vocational Education (SOTAVE):** Dr. Junior Martin\n    *   Contact: 970-5730\n*   **School of Humanities and Social Sciences:** Dr. Clover Jones McKenzie\n    *   Contact: 970-5300 / 970-5717\n*   **Student Affairs Assistants (General FELS):** 970-5423 / 970-5275\n\n**FACULTY OF LAW (FOLW)**\n*   **Dean (Actg.):** Marcia Robinson\n    *   Contact: 970-5238\n*   **Student Affairs Assistants (General FOLW):** 970-5530 / 5531 / 5238\n\n**FACULTY OF ENGINEERING AND COMPUTING (FENC)**\n*   **Dean:** Prof. Sean Thorpe\n    *   Contact: 970-5166\n*   **School of Engineering (SOE):** Dr. Shallon Stubbs\n    *   Contact: 970-5220 / 970-5244\n*   **School of Computing and Information Technology (SCIT):** Dr. David White\n    *   Contact: 970-5160\n*   **Student Affairs Assistants (General FENC):** 970-5163 / 5044 / 5153 / 5246 / 5165\n\n**FACULTY OF SCIENCE AND SPORT (FOSS)**\n*   **Dean:** Prof. Samson Omoregie\n    *   Contact: 970-5860 / 5866\n*   **Caribbean School of Sport Sciences (CSOSS) (Actg.):** Dr. Melissa Sanderson\n    *   Contact: 970-5869\n*   **School of Mathematics and Statistics (SOMAS):** Ave Maria McIntosh\n    *   Contact: 970-5872\n*   **School of Natural and Applied Sciences (Actg.):** Dr. Nikki Bramwell\n    *   Contact: 970-5287\n*   **Student Affairs Assistant (General FOSS):** 970-5860', '2025-09-14 00:49:39', NULL),
(19, 6, 'user', 'thank you', '2025-09-14 00:50:13', NULL),
(20, 6, 'AI', 'You\'re most welcome! Is there anything else I can help you with today?', '2025-09-14 00:50:13', NULL),
(21, 7, 'user', 'another day', '2025-09-14 00:53:37', NULL),
(22, 7, 'AI', 'Alright, have a great day! Feel free to reach out if you need anything else.', '2025-09-14 00:53:37', NULL),
(23, 7, 'user', 'did you know people call utech a patty shop', '2025-09-14 00:54:09', NULL),
(24, 7, 'AI', 'I understand that some people may use colloquial terms for UTECH. As a university chat bot assistant, I\'m here to provide you with official information and assistance regarding UTECH Jamaica.\n\nIs there something specific about the university I can help you with today?', '2025-09-14 00:54:09', NULL),
(25, 7, 'user', 'would u not want to know why utech is called a patty shop', '2025-09-14 00:54:41', NULL),
(26, 7, 'AI', 'I understand your curiosity, but as a university chat bot assistant, my main function is to provide official information and assistance about UTECH Jamaica. My knowledge base is focused on the academic and administrative aspects of the university.\n\nIs there anything specific about UTECH\'s official information that I can help you with right now?', '2025-09-14 00:54:41', NULL);

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
(1, 'e46e28e4-4872-4c30-95e8-360f391ea64f', 'johndoe@students.utech.edu.jm', '2025-09-13 20:07:05', NULL),
(2, '84529312-1725-40d4-b155-4e37d53c7c74', 'johndoe@students.utech.edu.jm', '2025-09-13 20:16:29', NULL),
(3, 'b4998788-b226-458c-8494-02e838ca2aed', 'johndoe@students.utech.edu.jm', '2025-09-13 20:21:22', NULL),
(4, '13342b46-7c8e-45ab-b179-468b4443ef3e', 'johndoe@students.utech.edu.jm', '2025-09-13 20:26:44', NULL),
(5, 'b7624510-c838-4380-80b7-3ff58732489a', 'johndoe@students.utech.edu.jm', '2025-09-13 20:35:38', NULL),
(6, '4a793fef-1173-4aa0-b083-3df5262c503a', 'johndoe@students.utech.edu.jm', '2025-09-14 00:45:03', NULL),
(7, 'c2b75164-b5cf-4a0f-8c6a-f05d0709c763', 'johndoe@students.utech.edu.jm', '2025-09-14 00:53:37', NULL);

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
('johndoe@students.utech.edu.jm', 'John', 'doe', '$2b$12$I2PZP9DapRBddS.Eo1ezzeahxt04.KhXOnRBA9vp61lptm7p8nAXS'),
('rjames@students.utech.edu.jm', 'Roberto', 'James', '$2b$12$jdjZrORk4gPAwQ8l6pCuOemXgbsTPd4.Jt7HpMWklrUQkXe7gOF82'),
('robertojjames5@students.utech.edu.jm', 'Roberto', 'James', '$2b$12$ZtE95tZDemiP52zaFoKjGuGhPdjE6Nv6jiQoChZ6K1y3waB4L37Yu'),
('robertojjames@students.utech.edu.jm', 'Roberto', 'James', '$2b$12$cTmr8J5rim80Ho5X2vnQjOdOhe5d7OA/i1vkk1O3v3K2BfbRaMRuO');

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
('johndoe@students.utech.edu.jm', '$2b$12$p7T81shmrrTM9oGSnrxAVOSn30T0kO5OYQ2Qhwtr/LHaUfvpkaHlm', 1, '2025-09-01 19:54:14', '2025-09-01 22:39:21'),
('rjames@students.utech.edu.jm', '$2b$12$P9.0jIee2hEEIFZO2wIR0eLUg4G0ADr62VQB7i3RyMI8Q1.VVT2.2', 0, '2025-09-01 18:38:05', '2025-09-01 18:38:05'),
('robertojjames5@students.utech.edu.jm', '$2b$12$cv2755l9X415nK3eOfKSb.HG3Kcr0tCRlOm4fH8HqQRePKlPEdXW.', 0, '2025-09-01 19:29:28', '2025-09-01 19:29:28');

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
  MODIFY `message_id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=27;

--
-- AUTO_INCREMENT for table `conversation`
--
ALTER TABLE `conversation`
  MODIFY `conversation_id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

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
