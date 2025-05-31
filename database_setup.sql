-- LynLift Database Schema Setup
-- Run this in your Supabase SQL Editor

-- 1. Add missing columns to workouts table
ALTER TABLE workouts 
ADD COLUMN IF NOT EXISTS paused_duration INTERVAL DEFAULT INTERVAL '0 seconds';

-- 2. Create workout_exercises table (intermediate table between workouts and exercises)
CREATE TABLE IF NOT EXISTS workout_exercises (
    id SERIAL PRIMARY KEY,
    workout_id INTEGER REFERENCES workouts(id) ON DELETE CASCADE,
    exercise_id INTEGER REFERENCES exercises(id) ON DELETE CASCADE,
    added_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(workout_id, exercise_id)
);

-- 3. Update sets table to reference workout_exercises
ALTER TABLE sets 
ADD COLUMN IF NOT EXISTS workout_exercise_id INTEGER REFERENCES workout_exercises(id) ON DELETE CASCADE;

-- 4. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_workout_exercises_workout_id ON workout_exercises(workout_id);
CREATE INDEX IF NOT EXISTS idx_workout_exercises_exercise_id ON workout_exercises(exercise_id);
CREATE INDEX IF NOT EXISTS idx_sets_workout_exercise_id ON sets(workout_exercise_id);

-- 5. Enable Row Level Security on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE sets ENABLE ROW LEVEL SECURITY;
ALTER TABLE body_weights ENABLE ROW LEVEL SECURITY;

-- 6. Create RLS policies for users
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (auth.uid() = id);

-- 7. Create RLS policies for workouts
CREATE POLICY "Users can view own workouts" ON workouts
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own workouts" ON workouts
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own workouts" ON workouts
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own workouts" ON workouts
    FOR DELETE USING (auth.uid() = user_id);

-- 8. Create RLS policies for exercises
CREATE POLICY "Users can view own exercises" ON exercises
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own exercises" ON exercises
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own exercises" ON exercises
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own exercises" ON exercises
    FOR DELETE USING (auth.uid() = user_id);

-- 9. Create RLS policies for workout_exercises
CREATE POLICY "Users can view own workout exercises" ON workout_exercises
    FOR SELECT USING (
        auth.uid() IN (
            SELECT user_id FROM workouts WHERE id = workout_exercises.workout_id
        )
    );

CREATE POLICY "Users can insert own workout exercises" ON workout_exercises
    FOR INSERT WITH CHECK (
        auth.uid() IN (
            SELECT user_id FROM workouts WHERE id = workout_exercises.workout_id
        )
    );

CREATE POLICY "Users can update own workout exercises" ON workout_exercises
    FOR UPDATE USING (
        auth.uid() IN (
            SELECT user_id FROM workouts WHERE id = workout_exercises.workout_id
        )
    );

CREATE POLICY "Users can delete own workout exercises" ON workout_exercises
    FOR DELETE USING (
        auth.uid() IN (
            SELECT user_id FROM workouts WHERE id = workout_exercises.workout_id
        )
    );

-- 10. Create RLS policies for sets
CREATE POLICY "Users can view own sets" ON sets
    FOR SELECT USING (
        auth.uid() IN (
            SELECT w.user_id 
            FROM workouts w 
            WHERE w.id = sets.workout_id
        )
    );

CREATE POLICY "Users can insert own sets" ON sets
    FOR INSERT WITH CHECK (
        auth.uid() IN (
            SELECT w.user_id 
            FROM workouts w 
            WHERE w.id = sets.workout_id
        )
    );

CREATE POLICY "Users can update own sets" ON sets
    FOR UPDATE USING (
        auth.uid() IN (
            SELECT w.user_id 
            FROM workouts w 
            WHERE w.id = sets.workout_id
        )
    );

CREATE POLICY "Users can delete own sets" ON sets
    FOR DELETE USING (
        auth.uid() IN (
            SELECT w.user_id 
            FROM workouts w 
            WHERE w.id = sets.workout_id
        )
    );

-- 11. Create RLS policies for body_weights
CREATE POLICY "Users can view own body weights" ON body_weights
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own body weights" ON body_weights
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own body weights" ON body_weights
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own body weights" ON body_weights
    FOR DELETE USING (auth.uid() = user_id);

-- 12. Create functions for exercise performance
CREATE OR REPLACE FUNCTION get_exercise_performance(exercise_id_param UUID)
RETURNS TABLE (
    weight FLOAT4,
    reps INT4,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT s.weight, s.reps, s.created_at
    FROM sets s
    JOIN workouts w ON s.workout_id = w.id
    WHERE s.exercise_id = exercise_id_param
      AND w.user_id = auth.uid()
      AND w.ended_at IS NOT NULL
    ORDER BY s.created_at DESC
    LIMIT 10;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 13. Create function to get workout stats
CREATE OR REPLACE FUNCTION get_workout_stats()
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'monthly_count', (
            SELECT COUNT(*)
            FROM workouts
            WHERE user_id = auth.uid()
              AND started_at >= date_trunc('month', CURRENT_DATE)
              AND ended_at IS NOT NULL
        ),
        'weekly_count', (
            SELECT COUNT(*)
            FROM workouts
            WHERE user_id = auth.uid()
              AND started_at >= date_trunc('week', CURRENT_DATE)
              AND ended_at IS NOT NULL
        )
    ) INTO result;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER; 