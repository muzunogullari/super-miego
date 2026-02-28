import Foundation

struct AssetNames {
    // MARK: - Player
    struct Player {
        static let smallIdle = "player_small_idle"
        static let smallWalk = "player_small_walk"
        static let smallJump = "player_small_jump"
        static let smallDeath = "player_small_death"

        static let superIdle = "player_super_idle"
        static let superWalk = "player_super_walk"
        static let superJump = "player_super_jump"
        static let superCrouch = "player_super_crouch"

        static let fireIdle = "player_fire_idle"
        static let fireWalk = "player_fire_walk"
        static let fireJump = "player_fire_jump"
        static let fireShoot = "player_fire_shoot"

        static let grow = "player_grow"
        static let shrink = "player_shrink"
    }

    // MARK: - Enemies
    struct Enemy {
        static let goombaWalk = "goomba_walk"
        static let goombaDead = "goomba_dead"

        static let koopaWalk = "koopa_walk"
        static let koopaShell = "koopa_shell"
        static let koopaShellSpin = "koopa_shell_spin"

        static let piranhaIdle = "piranha_idle"
        static let piranhaBite = "piranha_bite"
    }

    // MARK: - Blocks
    struct Block {
        static let ground = "block_ground"
        static let groundTop = "block_ground_top"
        static let brick = "block_brick"
        static let brickParticle = "block_brick_particle"
        static let question = "block_question"
        static let questionHit = "block_question_hit"
        static let empty = "block_empty"
        static let pipe = "block_pipe"
        static let pipeTop = "block_pipe_top"
    }

    // MARK: - Items
    struct Item {
        static let coin = "item_coin"
        static let coinSpin = "item_coin_spin"
        static let mushroom = "item_mushroom"
        static let fireFlower = "item_fire_flower"
        static let star = "item_star"
        static let oneUp = "item_1up"
        static let fireball = "item_fireball"
    }

    // MARK: - Environment
    struct Environment {
        static let cloud = "env_cloud"
        static let tree = "env_tree"
        static let bush = "env_bush"
        static let mountain = "env_mountain"
        static let water = "env_water"
        static let flagpole = "env_flagpole"
        static let flag = "env_flag"
        static let castle = "env_castle"
    }

    // MARK: - Backgrounds
    struct Background {
        static let sky = "bg_sky"
        static let farMountains = "bg_far_mountains"
        static let nearTrees = "bg_near_trees"
        static let mist = "bg_mist"
    }

    // MARK: - UI
    struct UI {
        static let pauseButton = "ui_pause"
        static let playButton = "ui_play"
        static let coinIcon = "ui_coin_icon"
        static let lifeIcon = "ui_life_icon"
        static let titleLogo = "ui_title"
        static let gameOver = "ui_game_over"
    }

    // MARK: - Audio
    struct Audio {
        static let jumpSmall = "sfx_jump_small"
        static let jumpSuper = "sfx_jump_super"
        static let coin = "sfx_coin"
        static let powerUp = "sfx_powerup"
        static let powerDown = "sfx_powerdown"
        static let stomp = "sfx_stomp"
        static let kick = "sfx_kick"
        static let bump = "sfx_bump"
        static let breakBlock = "sfx_break"
        static let fireball = "sfx_fireball"
        static let death = "sfx_death"
        static let gameOver = "sfx_gameover"
        static let levelClear = "sfx_levelclear"
        static let flagpole = "sfx_flagpole"
        static let oneUp = "sfx_1up"
        static let pause = "sfx_pause"

        static let bgmLevel = "bgm_level"
        static let bgmInvincible = "bgm_invincible"
    }
}
