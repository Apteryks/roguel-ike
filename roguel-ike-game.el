;;; roguel-ike-game.el --- Game state

;;; Commentary:
;;

;;; Code:

(require 'eieio)
(require 'roguel-ike-level)
(require 'roguel-ike-entity)
(require 'roguel-ike-buffer)

(defclass rlk--game ()
  ((current-grid :initarg :grid
                 :type rlk--level-grid
                 :reader get-current-grid
                 :writer set-current-grid
                 :protection :private
                 :documentation "Current grid to display.")
   (hero :initarg :hero
         :type rlk--entity-hero
         :reader get-hero
         :protection :private
         :documentation "Player's character.")
   (enemies :initform ()
            :type list
            :reader get-enemies
            :writer set-enemies
            :protection :private
            :documentation "Living entities hostiles to the player.")
   (buffer-manager :initarg :buffer-manager
                   :type rlk--buffer-manager
                   :reader get-buffer-manager
                   :protection :private
                   :documentation "Game's buffer manager."))
  "Contain the game state.")

(defmethod add-enemy ((game rlk--game) enemy)
  "Add an enemy to the enemies list."
  (let ((enemies (get-enemies game)))
    (set-enemies game (add-to-list 'enemies enemy))))

(defmethod remove-enemy ((game rlk--game) enemy)
  "Remove an enemy from the enemies list."
  (set-enemies game (delete enemy (get-enemies game))))

(defmethod update-enemies ((game rlk--game))
  "Let enemies spend their time delay."
  (let (enemies-to-update '())
    ;; Get all enemies with a negative time delay
    (dolist (enemy (get-enemies game))
      (when (can-do-action enemy)
        (add-to-list 'enemies-to-update enemy)))
    ;; Update enemies one by one, turn by turn, as long as there is one
    ;; with time to spend
    (while enemies-to-update
      (let ((enemies enemies-to-update))
        (dolist (enemy enemies)
          (update enemy)
          (unless (can-do-action enemy)
            (setq enemies-to-update (delete enemy enemies-to-update))))))))

(defmethod add-time-delay-enemies ((game rlk--game) time)
  "Add TIME to all enemies' time delay."
  (dolist (enemy (get-enemies game))
    (add-time-delay enemy time)))

(provide 'roguel-ike-game)

;;; roguel-ike-game.el ends here
