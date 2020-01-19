rm /Users/peeters/Documents/Developement/informatiCUP-2020/swift_trainer_2/UnitTests/GPUFunctions.metallib

xcrun -sdk macosx metal /Users/peeters/Documents/Developement/informatiCUP-2020/swift_trainer_2/Sources/InformatiCUP/GPUFunctions.metal -c -o /Users/peeters/Documents/Developement/informatiCUP-2020/swift_trainer_2/UnitTests/GPUFunctions.air

xcrun -sdk macosx metallib /Users/peeters/Documents/Developement/informatiCUP-2020/swift_trainer_2/UnitTests/GPUFunctions.air -o /Users/peeters/Documents/Developement/informatiCUP-2020/swift_trainer_2/UnitTests/GPUFunctions.metallib

rm /Users/peeters/Documents/Developement/informatiCUP-2020/swift_trainer_2/UnitTests/GPUFunctions.air
