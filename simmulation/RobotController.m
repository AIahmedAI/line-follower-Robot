% ==============================================================================
% RobotController.m  -  Place this file in your MATLAB working directory
% ==============================================================================
classdef RobotController < handle
    properties
        % State constants (match Arduino enum)
        STATE_EXPLORING = 0;
        STATE_RETURNING = 1;
        STATE_COMPLETED = 2;

        currentState = 0;   % Start in EXPLORING

        % Motion constants (match Arduino values)
        BASE_SPEED     = 160;
        TURN_SPEED     = 130;
        OBSTACLE_LIMIT = 20; % cm

        % Timing variables (seconds)
        lineLostStartTime = 0;
        LINE_LOST_TIMEOUT = 1.5;
        uTurnStartTime    = 0;
        U_TURN_TIME       = 1.2;

        % Obstacle-avoidance state
        servoAngle         = 90;
        avoidanceStartTime = 0;
        isAvoiding         = false;

        % Current motor PWM commands
        targetLeftPWM  = 0;
        targetRightPWM = 0;
    end

    methods
        % ------------------------------------------------------------------
        % update()  -  called every simulation step
        %   Inputs : distance (cm), l2, l1, r1, r2 (0=line, 1=no line),
        %            currentTime (s)
        %   Outputs: outLeft, outRight  (motor PWM values)
        % ------------------------------------------------------------------
        function [outLeft, outRight] = update(obj, distance, l2, l1, r1, r2, currentTime)

            % 1. Mission complete -> stop
            if obj.currentState == obj.STATE_COMPLETED
                [outLeft, outRight] = obj.stopRobot();
                return;
            end

            % 2. Obstacle avoidance
            if distance > 0 && distance < obj.OBSTACLE_LIMIT && ~obj.isAvoiding
                [outLeft, outRight] = obj.avoidObstacle(currentTime);
                return;
            end

            % 3. Read line sensors
            [position, isIntersection] = obj.readLineSensors(l2, l1, r1, r2);

            % 4. Intersection while returning -> done
            if obj.currentState == obj.STATE_RETURNING && isIntersection
                obj.currentState = obj.STATE_COMPLETED;
                [outLeft, outRight] = obj.stopRobot();
                return;
            end

            % 5. Steering logic
            switch position
                case 0          % Straight
                    [outLeft, outRight] = obj.moveForward();
                    obj.lineLostStartTime = 0;

                case {-1, -2}   % Drift left -> correct right
                    [outLeft, outRight] = obj.turnLeft();
                    obj.lineLostStartTime = 0;

                case {1, 2}     % Drift right -> correct left
                    [outLeft, outRight] = obj.turnRight();
                    obj.lineLostStartTime = 0;

                case 99         % Line lost
                    if obj.lineLostStartTime == 0
                        obj.lineLostStartTime = currentTime;
                    end

                    elapsed = currentTime - obj.lineLostStartTime;
                    if elapsed > obj.LINE_LOST_TIMEOUT
                        if obj.currentState == obj.STATE_EXPLORING
                            [outLeft, outRight] = obj.performUTurn(currentTime);
                        else
                            [outLeft, outRight] = obj.stopRobot();
                            obj.currentState = obj.STATE_COMPLETED;
                        end
                    else
                        % Keep last command while searching
                        outLeft  = obj.targetLeftPWM;
                        outRight = obj.targetRightPWM;
                    end

                otherwise
                    [outLeft, outRight] = obj.stopRobot();
            end
        end

        % ------------------------------------------------------------------
        % Motor helpers
        % ------------------------------------------------------------------
        function [L, R] = stopRobot(obj)
            obj.targetLeftPWM  = 0;
            obj.targetRightPWM = 0;
            L = 0;  R = 0;
        end

        function [L, R] = moveForward(obj)
            obj.targetLeftPWM  = obj.BASE_SPEED;
            obj.targetRightPWM = obj.BASE_SPEED;
            L = obj.targetLeftPWM;
            R = obj.targetRightPWM;
        end

        function [L, R] = turnLeft(obj)
            obj.targetLeftPWM  = -obj.TURN_SPEED;
            obj.targetRightPWM =  obj.TURN_SPEED;
            L = obj.targetLeftPWM;
            R = obj.targetRightPWM;
        end

        function [L, R] = turnRight(obj)
            obj.targetLeftPWM  =  obj.TURN_SPEED;
            obj.targetRightPWM = -obj.TURN_SPEED;
            L = obj.targetLeftPWM;
            R = obj.targetRightPWM;
        end

        % ------------------------------------------------------------------
        % readLineSensors()
        %   Returns position code and intersection flag.
        %   Sensor convention: 0 = detects line (black), 1 = no line (white)
        % ------------------------------------------------------------------
        function [pos, isIntersect] = readLineSensors(~, l2, l1, r1, r2)
            isIntersect = (l2 == 0 && r2 == 0);

            if    (l1 == 0 && r1 == 0),  pos =  0;   % centered
            elseif(l1 == 0 && r1 == 1),  pos = -1;   % slight left
            elseif(r1 == 0 && l1 == 1),  pos =  1;   % slight right
            elseif(l2 == 0),              pos = -2;   % hard left
            elseif(r2 == 0),              pos =  2;   % hard right
            else,                         pos = 99;   % line lost
            end
        end

        % ------------------------------------------------------------------
        % performUTurn()
        % ------------------------------------------------------------------
        function [L, R] = performUTurn(obj, currentTime)
            if obj.uTurnStartTime == 0
                obj.uTurnStartTime = currentTime;
            end
            t = currentTime - obj.uTurnStartTime;

            if t < 0.5                          % brief stop
                [L, R] = obj.stopRobot();
            elseif t < 0.5 + obj.U_TURN_TIME    % spin
                [L, R] = obj.turnRight();
            else                                % done
                obj.currentState   = obj.STATE_RETURNING;
                obj.uTurnStartTime = 0;
                [L, R] = obj.stopRobot();
            end
        end

        % ------------------------------------------------------------------
        % avoidObstacle()  -  Open-loop avoidance manoeuvre
        % ------------------------------------------------------------------
        function [L, R] = avoidObstacle(obj, currentTime)
            if obj.avoidanceStartTime == 0
                obj.avoidanceStartTime = currentTime;
                obj.isAvoiding = true;
            end
            t = currentTime - obj.avoidanceStartTime;

            if    t < 0.5,  [L, R] = obj.stopRobot();
            elseif t < 1.0, obj.servoAngle = 30; [L, R] = obj.stopRobot();
            elseif t < 1.5, [L, R] = obj.turnRight();
            elseif t < 2.5, [L, R] = obj.moveForward();
            elseif t < 3.0, [L, R] = obj.turnLeft();
            else
                obj.isAvoiding         = false;
                obj.avoidanceStartTime = 0;
                obj.servoAngle         = 90;
                [L, R] = obj.moveForward();
            end
        end
    end
end
