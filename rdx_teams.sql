USE `redm_extended`;

CREATE TABLE `rdx_teams` (
	`identifier` VARCHAR(50) NOT NULL COLLATE 'utf8mb4_general_ci',
	`name` VARCHAR(50) NOT NULL COLLATE 'utf8mb4_general_ci',
	`team` VARCHAR(50) NOT NULL COLLATE 'utf8mb4_general_ci',
	`isLeader` VARCHAR(50) NOT NULL COLLATE 'utf8mb4_general_ci'
);