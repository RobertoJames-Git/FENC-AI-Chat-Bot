-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Dec 20, 2025 at 05:22 AM
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `soft_delete_last_5_conversations_if_safe` (IN `p_email` VARCHAR(255))   BEGIN
    DECLARE v_total_conversations INT DEFAULT 0;

    -- Rollback on any SQL error
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
    END;

    -- Count ONLY active (not deleted) conversations
    SELECT COUNT(*)
    INTO v_total_conversations
    FROM conversation
    WHERE LOWER(email) = LOWER(p_email)
      AND deleted_at IS NULL;

    -- Must leave at least 2 conversations remaining
    IF v_total_conversations >= 7 THEN

        START TRANSACTION;

        -- Soft delete the latest 5 conversations
        UPDATE conversation
        SET deleted_at = NOW()
        WHERE conversation_id IN (
            SELECT conversation_id
            FROM (
                SELECT conversation_id
                FROM conversation
                WHERE LOWER(email) = LOWER(p_email)
                  AND deleted_at IS NULL
                ORDER BY started_at DESC
                LIMIT 5
            ) AS last_five
        );

        COMMIT;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `store_new_conversation` (IN `p_email` VARCHAR(255), IN `p_token_uuid` CHAR(36), IN `p_user_message` TEXT, IN `p_ai_message` TEXT)   BEGIN
    DECLARE v_conversation_id BIGINT;
    DECLARE v_started_at TIMESTAMP;

    -- Insert into conversation
    INSERT INTO conversation (token_UUID, email)
    VALUES (p_token_uuid, p_email);

    SET v_conversation_id = LAST_INSERT_ID();

    -- Get the started_at timestamp
    SELECT started_at INTO v_started_at
    FROM conversation
    WHERE conversation_id = v_conversation_id;

    -- Insert user message
    INSERT INTO chat_history (conversation_id, role, message)
    VALUES (v_conversation_id, 'user', p_user_message);

    -- Insert AI response
    INSERT INTO chat_history (conversation_id, role, message)
    VALUES (v_conversation_id, 'AI', p_ai_message);

    -- Return values
    SELECT p_token_uuid AS token_uuid,
           v_started_at AS convo_timestamp;
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
(12, 15, 'AI', 'The University of Technology, Jamaica has several Colleges and Faculties. Here they are:\n\n*   **College of Business & Management (COBAM)**\n*   **College of Health Sciences (COHS)**\n*   **Faculty of Education & Liberal Studies (FELS)**\n*   **Faculty of Engineering & Computing (FENC)**\n*   **Faculty of Law (FOLW)**\n*   **Faculty of Science and Sport (FOSS)**\n*   **Faculty of the Built Environment (FOBE)**\n*   **Joint Colleges of Medicine, Oral Health and Veterinary Sciences** (this entity comprises the College of Medicine, College of Oral Health Sciences, and College of Veterinary Sciences).', '2025-11-23 03:14:29'),
(13, 14, 'user', 'where can i go for internships', '2025-11-23 03:23:50'),
(14, 14, 'AI', 'For internships and other work experience opportunities, you can explore the following options at UTech Jamaica:\n\n1.  **Co-operative Education Unit**:\n    *   This unit facilitates structured integration of classroom learning with on-the-job work experiences, often referred to as internships, work experience, practicum, or professional practice.\n    *   These modules are generally available to students from their second to final year of study and are mandatory for most courses. Students can also participate voluntarily.\n    *   The unit assists with recruiting employers, direct student placements, preparing students for industry engagement, and supervising students during their engagement.\n    *   You can find more information on their website: http://www.utech.edu.jm/academics/aca-demics/cooped\n    *   Visit the Unit located on St. Kitts Close (across from Lillian’s Restaurant) Monday to Friday from 8:00 a.m. – 4:00 p.m.\n    *   Contact: (876) 927-1680-8 ext 2820/3536 or email sjunor@utech.edu.jm; ced@utech.edu.jm.\n\n2.  **Career and Placement Unit**:\n    *   This unit helps students and alumni gain employment or exposure to the working world, including company-initiated internships and referrals for internship opportunities.\n    *   They offer services like career advisement, resume clinics, mock interviews, and employment empowerment sessions.\n    *   To participate, you can email placement@utech.edu.jm, call (876) 970-5030/5267, or visit the Department of Student Services on the Papine Campus.', '2025-11-23 03:23:50'),
(15, 16, 'user', 'what was the first question I asked', '2025-11-23 23:57:26'),
(16, 16, 'AI', 'I\'m here to assist with questions about UTech Jamaica. For topics outside the university, I recommend consulting another source.', '2025-11-23 23:57:26'),
(17, 16, 'user', 'okay understood', '2025-11-29 17:07:15'),
(18, 16, 'AI', 'I understand you\'re asking to recall your first question. My current conversation history begins with your query: \"what was the first question I asked\". I don\'t have access to details about any questions asked before this point in our interaction.', '2025-11-29 17:07:15'),
(19, 16, 'user', 'who is the dean of FELS?', '2025-11-29 17:07:45'),
(20, 16, 'AI', 'The Dean of FELS is Dr. Harold McDermott.', '2025-11-29 17:07:45'),
(21, 16, 'user', 'thank you for the assistance.\n\n\n\nI understand', '2025-11-29 17:27:01'),
(22, 16, 'AI', 'You\'re most welcome! Feel free to ask if you have any more questions about UTech Jamaica.', '2025-11-29 17:27:01'),
(23, 16, 'user', 'who can i contact for job opportunities.\n\nThe DEAN?\nCarrer placement unit?\nThe Presi?', '2025-11-29 17:28:24'),
(24, 16, 'AI', 'For job opportunities, you should primarily contact the **Career and Placement Unit**.\n\nThe Career and Placement Unit is specifically dedicated to assisting students and graduates with employment and entrepreneurship, including job placement. You can reach them at:\n\n*   **Email:** placement@utech.edu.jm\n*   **Telephone:** (876) 970-5030 / (876) 970-5267\n*   **In-person:** Department of Student Services, Papine Campus\n*   **Opening Hours:** Monday–Friday, 8:00 a.m. – 4:00 p.m.\n\nThe Career and Placement Officer is Charmaine Lewis.\n\nAdditionally, the Co-operative Education Unit also assists with recruitment and placement for work experiences related to your course of study. You can contact them at (876) 927-1680-8 ext 2820/3536 or via email at sjunor@utech.edu.jm; ced@utech.edu.jm.\n\nThe Alumni Relations Office also offers opportunities for networking and mentorship that can assist with career development. You can contact Ms. Cheryll Messam, Alumni Relations Manager, at utech.alumni@utech.edu.jm or (876) 970-5468.', '2025-11-29 17:28:24'),
(25, 16, 'user', 'can i ask UWI for assistance too?\nor not', '2025-11-29 17:29:16'),
(26, 16, 'AI', 'I\'m here to assist with questions about UTech Jamaica. For topics outside the university, I recommend consulting another source.', '2025-11-29 17:29:16'),
(27, 16, 'user', 'thank you understood', '2025-11-29 17:30:11'),
(28, 16, 'AI', 'You\'re most welcome! Feel free to ask if you have any more questions about UTech Jamaica.', '2025-11-29 17:30:11'),
(29, 16, 'user', 'Okay thank you', '2025-11-29 17:43:37'),
(30, 16, 'AI', 'You\'re most welcome! Feel free to ask if you have any more questions about UTech Jamaica.', '2025-11-29 17:43:37'),
(31, 16, 'user', 'thats fine', '2025-11-29 18:24:10'),
(32, 16, 'AI', 'You\'re most welcome! Feel free to ask if you have any more questions about UTech Jamaica.', '2025-11-29 18:24:10'),
(33, 16, 'user', 'what was the first question i asked you', '2025-11-29 18:24:37'),
(34, 16, 'AI', 'I understand you\'re asking to recall your first question. My current conversation history begins with your query: \"what was the first question I asked\". I don\'t have access to details about any questions asked before this point in our interaction.', '2025-11-29 18:24:37'),
(35, 17, 'user', 'hello', '2025-11-29 21:42:09'),
(36, 17, 'AI', 'Hello! I\'m your UTech Jamaica chat assistant. How may I help you today with questions about the university?', '2025-11-29 21:42:09'),
(37, 17, 'user', 'how are you', '2025-11-29 22:25:17'),
(38, 17, 'AI', 'I am functioning perfectly and ready to assist you! How may I help you today with questions about UTech Jamaica?', '2025-11-29 22:25:17'),
(39, 17, 'user', 'how is the president', '2025-11-29 22:27:37'),
(40, 17, 'AI', 'The President of UTech Jamaica is Dr. Kevin Brown. As an AI assistant, I don\'t have information on his personal well-being, but he recently extended a welcome message to all students for the 2024/2025 Academic Year.', '2025-11-29 22:27:37'),
(41, 17, 'user', 'thank you', '2025-11-29 22:30:57'),
(42, 17, 'AI', 'You\'re most welcome! Is there anything else I can help you with regarding UTech Jamaica today?', '2025-11-29 22:30:57'),
(43, 17, 'user', 'who is the dean of all faculties', '2025-11-29 22:31:19'),
(44, 17, 'AI', 'There isn\'t a single \"dean of all faculties\" at UTech Jamaica. Each College and Faculty has its own Dean.\n\nHere are the Deans for each:\n\n*   **COLLEGE OF BUSINESS AND MANAGEMENT (COBAM):** Olubusola Akinladejo (Actg.)\n*   **COLLEGE OF HEALTH SCIENCES (COHS):** Dr. Adella Campbell\n*   **FACULTY OF THE BUILT ENVIRONMENT (FOBE):** Dr. Laurence Neufville\n*   **FACULTY OF EDUCATION AND LIBERAL STUDIES (FELS):** Dr. Harold McDermott\n*   **FACULTY OF LAW (FOLW):** Marcia Robinson (Actg.)\n*   **FACULTY OF ENGINEERING AND COMPUTING (FENC):** Prof. Sean Thorpe\n*   **FACULTY OF SCIENCE AND SPORT (FOSS):** Prof. Samson Omoregie', '2025-11-29 22:31:19'),
(45, 17, 'user', 'thankyou', '2025-11-30 00:03:56'),
(46, 17, 'AI', 'You\'re most welcome! Is there anything else I can help you with regarding UTech Jamaica today?', '2025-11-30 00:03:56'),
(47, 17, 'user', 'who can i ask for a job', '2025-11-30 00:06:31'),
(48, 17, 'AI', 'You can ask the **Career and Placement Unit** for assistance with job-related inquiries.\n\nThe Career and Placement Officer is **Charmaine Lewis**.\n\nThe Unit offers a range of services to help students and graduates with employment and entrepreneurship, including:\n*   Career Advisement\n*   Résumé Clinic\n*   Mock Interviews\n*   Employment Empowerment Sessions\n*   Mentoring Programme\n*   Annual Job Fair\n*   Job Placement (full-time, part-time, internships, seasonal, voluntary)\n\nYou can contact them by:\n*   **Email:** placement@utech.edu.jm\n*   **Telephone:** (876) 970-5030 / 5267\n*   **Visiting their office:** Department of Student Services (Papine Campus)\n\nTheir operating hours are Monday to Friday, 8:00 a.m. – 4:00 p.m.\n\nAdditionally, you might be interested in the **Co-operative Education Unit**, which facilitates structured on-the-job work experiences and internships. You can reach them at (876) 927-1680-8 ext2820/3536 or via email at sjunor@utech.edu.jm; ced@utech.edu.jm.', '2025-11-30 00:06:31'),
(49, 18, 'user', 'that was fun', '2025-11-30 03:06:58'),
(50, 18, 'AI', 'That\'s great to hear! I\'m glad I could assist.\n\nIs there anything else I can help you with today?', '2025-11-30 03:06:58'),
(51, 19, 'user', 'that is cool', '2025-11-30 03:09:07'),
(52, 19, 'AI', 'Glad you think so! Is there anything else I can help you with today? Feel free to ask if you have any questions about UTECH, our programs, or anything else.', '2025-11-30 03:09:07'),
(53, 20, 'user', 'hello how is it going', '2025-12-01 01:58:05'),
(54, 20, 'AI', 'Hello! I\'m doing well, thank you. How can I assist you today?', '2025-12-01 01:58:05'),
(55, 20, 'user', 'what are the rules of the unoversity', '2025-12-01 01:58:44'),
(56, 20, 'AI', 'The University has a comprehensive set of rules and regulations designed to ensure a productive and safe environment for all students. These rules cover various aspects of your academic journey and campus life.\n\nGenerally, the key areas covered include:\n\n*   **Academic Progress and Awards:** This involves regulations on maintaining a satisfactory GPA, academic probation, requirements for progressing through your course of study, and the criteria for receiving your degree, diploma, or certificate. It also covers policies like Grade Forgiveness, transfer credits, and exemptions.\n*   **Student Conduct and Discipline:** This outlines expected behaviour, classifications of offences (minor, major, gross misconduct), and the procedures and potential sanctions for breaches of discipline, including academic misconduct like plagiarism or cheating.\n*   **Financial Matters:** Details on tuition and ancillary fees, payment options, deadlines, payment plans, refunds, scholarships, sponsorships, and the implications of outstanding balances.\n*   **Registration and Enrolment:** Information on how to register for courses, add/drop modules, deferrals, and maintaining your student status.\n*   **Examinations:** Regulations concerning examination timetables, procedures during exams, dealing with examination clashes, rescheduling exams, reporting absences due to illness or other extenuating circumstances, and how to appeal a final grade.\n*   **Campus Safety and Security:** Guidelines on ID cards, parking, hall of residence rules, emergency procedures, and general safety advice.\n\nYou can find detailed information on all these aspects in the **Student Handbook** and the specific regulations (like Regulation 3, Regulation 4, Regulation 5, and Ordinance 1999/14).\n\nIs there a specific area of university rules you\'d like to know more about? I can provide more details if you narrow down your query.', '2025-12-01 01:58:44'),
(57, 20, 'user', 'what should i wear to school', '2025-12-01 01:58:55'),
(58, 20, 'AI', 'The University has a school dress code, and non-compliance with it is classified as a minor offence under Ordinance 1999/14 – Student Discipline.\n\nHowever, the specific details of the dress code (e.g., what is permitted or prohibited) are not provided in the current handbook sections I have access to.\n\nFor detailed information on the school\'s dress code, you would typically find it in the full **Student Handbook** or by consulting your Academic Advisor or relevant Student Affairs office.', '2025-12-01 01:58:55'),
(59, 20, 'user', 'hello', '2025-12-20 00:18:43'),
(60, 20, 'AI', 'Hello again! How can I assist you further today?', '2025-12-20 00:18:43'),
(61, 20, 'user', 'what was the first question i asked', '2025-12-20 00:18:59'),
(62, 20, 'AI', 'The first question you asked about university information was: \"what are the rules of the unoversity\".', '2025-12-20 00:18:59'),
(63, 21, 'user', 'hello', '2025-12-20 00:57:28'),
(64, 21, 'AI', 'Hello! Welcome to UTECH, Jamaica. How can I help you today?', '2025-12-20 00:57:28'),
(67, 23, 'user', 'new chat bro', '2025-12-20 01:03:50'),
(68, 23, 'AI', 'Hello there! I\'m your UTECH Jamaica chat assistant.\n\nHow can I help you today?', '2025-12-20 01:03:50'),
(69, 24, 'user', 'test', '2025-12-20 03:04:56'),
(70, 24, 'AI', 'Hello! How can I help you today as a UTECH, Jamaica assistant? Feel free to ask me anything about the university.', '2025-12-20 03:04:56'),
(71, 25, 'user', 'once', '2025-12-20 03:06:05'),
(72, 25, 'AI', 'Please provide more information. What would you like to know \"once\"?\n\nIf you have a question, please let me know!', '2025-12-20 03:06:05'),
(73, 26, 'user', 'hello what is up', '2025-12-20 04:10:19'),
(74, 26, 'AI', 'Hello! Not much, just here to help. How can I assist you today?', '2025-12-20 04:10:19'),
(75, 27, 'user', 'who is the student union rep', '2025-12-20 04:11:51'),
(76, 27, 'AI', 'The Students\' Union President is Rick Darby.', '2025-12-20 04:11:51'),
(77, 28, 'user', 'that is new', '2025-12-20 04:15:34'),
(78, 28, 'AI', 'It sounds like something I mentioned caught your attention! Could you please remind me what you\'re referring to as \"new\"? I\'m here to help with any UTECH Jamaica information you might need.', '2025-12-20 04:15:34');

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
(15, '0095b7c4-bce9-41f1-80f6-8a431e7cc243', 'john.doe@students.utech.edu.jm', '2025-11-23 03:14:29', NULL),
(16, 'd4190d1e-9538-43fb-9763-8bbe8bea0c4c', 'john.doe@students.utech.edu.jm', '2025-11-23 23:57:25', NULL),
(17, '227f6399-9227-4438-b781-3a0c3644b500', 'john.doe@students.utech.edu.jm', '2025-11-29 21:42:09', NULL),
(18, '1e860f52-9823-4ce5-b56f-db5349624225', 'john.doe@students.utech.edu.jm', '2025-11-30 03:06:58', NULL),
(19, 'fa19d7a0-2909-4c1a-b66a-500fdb18f5a1', 'john.doe@students.utech.edu.jm', '2025-11-30 03:09:07', NULL),
(20, 'c056209d-8886-4fc7-a547-94b8ad4736b2', 'john.doe@students.utech.edu.jm', '2025-12-01 01:58:05', NULL),
(21, '22dacde0-307a-43e3-8030-acf8ca71e197', 'john.doe@students.utech.edu.jm', '2025-12-20 00:57:28', NULL),
(23, 'c7f76586-0283-43cc-8bb7-752e3f9ac2ee', 'john.doe@students.utech.edu.jm', '2025-12-20 01:03:50', NULL),
(24, 'ddd0b26e-60d9-4825-ae2b-7ff05852929b', 'john.doe@students.utech.edu.jm', '2025-12-20 03:04:56', NULL),
(25, 'dfb30c85-79c9-4186-8144-9b0ab7c781a7', 'john.doe@students.utech.edu.jm', '2025-12-20 03:06:05', NULL),
(26, '66630610-4cc4-4d9d-9f56-2ed27bc5c7d4', 'john.doe@students.utech.edu.jm', '2025-12-20 04:10:19', NULL),
(27, '9d90a34f-e51b-4060-b3ce-da67049eac2f', 'john.doe@students.utech.edu.jm', '2025-12-20 04:11:51', NULL),
(28, '8ea7c6c2-26a6-48a5-b739-f48c1ffa73e3', 'john.doe@students.utech.edu.jm', '2025-12-20 04:15:34', NULL);

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
  MODIFY `message_id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=79;

--
-- AUTO_INCREMENT for table `conversation`
--
ALTER TABLE `conversation`
  MODIFY `conversation_id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=29;

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
