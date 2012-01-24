SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL';

CREATE SCHEMA IF NOT EXISTS `intrabox` DEFAULT CHARACTER SET utf8 ;
USE `intrabox` ;

-- -----------------------------------------------------
-- Table `intrabox`.`usergroups`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `intrabox`.`usergroups` (
  `id_usergroup` INT NOT NULL ,
  `rule_type` VARCHAR(45) NOT NULL ,
  `rule` VARCHAR(45) NOT NULL ,
  `quota` TINYINT NOT NULL ,
  `size_max` TINYINT NOT NULL ,
  `expiration_max` TINYINT NOT NULL ,
  PRIMARY KEY (`id_usergroup`) )
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `intrabox`.`admins`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `intrabox`.`admins` (
  `id_admin` INT NOT NULL ,
  `id_user` VARCHAR(45) NOT NULL ,
  PRIMARY KEY (`id_admin`) )
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `intrabox`.`status`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `intrabox`.`status` (
  `id_status` INT NOT NULL ,
  `name` VARCHAR(45) NOT NULL ,
  PRIMARY KEY (`id_status`) )
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `intrabox`.`deposits`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `intrabox`.`deposits` (
  `id_deposit` INT NOT NULL ,
  `id_user` VARCHAR(30) NOT NULL ,
  `download_code` VARCHAR(45) NOT NULL ,
  `area_access_code` VARCHAR(45) NULL DEFAULT NULL ,
  `area_to_email` VARCHAR(45) NULL DEFAULT NULL ,
  `area_size` TINYINT NULL DEFAULT NULL ,
  `opt_acknowledgement` TINYINT(1) NOT NULL DEFAULT FALSE ,
  `opt_downloads_report` TINYINT(1) NOT NULL DEFAULT FALSE ,
  `opt_comment` TINYTEXT NULL DEFAULT NULL ,
  `opt_password` VARCHAR(20) NULL DEFAULT NULL ,
  `id_status` INT NOT NULL ,
  `expiration_days` TINYINT NOT NULL ,
  `expiration_date` DATE NOT NULL ,
  `created_date` DATE NOT NULL ,
  `created_ip` VARCHAR(19) NOT NULL ,
  `created_useragent` VARCHAR(150) NOT NULL ,
  PRIMARY KEY (`id_deposit`, `id_status`) ,
  INDEX `fk_deposits_status1` (`id_status` ASC) ,
  CONSTRAINT `fk_deposits_status1`
    FOREIGN KEY (`id_status` )
    REFERENCES `intrabox`.`status` (`id_status` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `intrabox`.`files`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `intrabox`.`files` (
  `id_file` INT NOT NULL ,
  `id_deposit` INT NOT NULL ,
  `name` VARCHAR(60) NOT NULL ,
  `size` FLOAT NOT NULL ,
  `on_server` TINYINT(1) NOT NULL DEFAULT TRUE ,
  PRIMARY KEY (`id_file`, `id_deposit`) ,
  INDEX `fk_files_deposits` (`id_deposit` ASC) ,
  CONSTRAINT `fk_files_deposits`
    FOREIGN KEY (`id_deposit` )
    REFERENCES `intrabox`.`deposits` (`id_deposit` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `intrabox`.`downloads`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `intrabox`.`downloads` (
  `id_download` INT NOT NULL ,
  `id_deposit` INT NOT NULL ,
  `id_file` INT NOT NULL ,
  `ip` VARCHAR(19) NOT NULL ,
  `useragent` VARCHAR(150) NOT NULL ,
  `start_date` DATE NOT NULL ,
  `end_date` DATE NULL DEFAULT NULL ,
  `finished` TINYINT(1) NOT NULL DEFAULT FALSE ,
  PRIMARY KEY (`id_download`, `id_deposit`, `id_file`) ,
  INDEX `fk_downloads_files1` (`id_file` ASC, `id_deposit` ASC) ,
  CONSTRAINT `fk_downloads_files1`
    FOREIGN KEY (`id_file` , `id_deposit` )
    REFERENCES `intrabox`.`files` (`id_file` , `id_deposit` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;



SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
