# XQ Fitness

Offline iPhone app for training routines, customer-managed training sessions, exercises, and progress snapshots.

## Language

**Routine**:
A named training plan with optional notes, any number of training sessions, and progress snapshots.
_Avoid_: Workout plan, program, template

**Training session**:
A named session inside a routine, holding that session's exercises.
_Avoid_: Training day, workout

**Exercise**:
A named lift or movement on a training session, with sets, reps, and weight in kilograms.
_Avoid_: Movement, lift (as the entity name)

**Fitness snapshot**:
The versioned on-device document that holds all routines.
_Avoid_: Database, save file

**Routine snapshot**:
A point-in-time capture of aggregated exercise peaks across a routine's week.
_Avoid_: Checkpoint, log entry

**Snapshot report**:
The comparison of the latest routine snapshot with the previous one, including progress indicators.
_Avoid_: Diff, analytics

**Progress indicator**:
Whether reps or weight are first, increased, decreased, or maintained versus the previous routine snapshot.
_Avoid_: Trend, delta

**Fitness store**:
The observable domain owner that applies fitness commands, persists the fitness snapshot, and builds snapshot reports.
_Avoid_: Repository, ViewModel (for this module)

**Fitness command**:
An explicit write against the fitness store: create routine, add/update/delete exercise, or create routine snapshot.
_Avoid_: Action, mutation, event

**Routine editor**:
The presentation draft for creating a routine (name and notes) before it is saved through the fitness store.
_Avoid_: Routine form state, create-routine screen model (as the concept name)

**Exercise editor**:
The presentation draft for adding or updating an exercise on a training session, including hydrate-from-store and fail-closed edit when the target is missing.
_Avoid_: Exercise form state
