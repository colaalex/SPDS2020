from random import randint


with open('firmware.hex', 'w') as f:
    f.write('@00000000\n')
    for i in range(16):
        num = randint(0, 255)
        num_hex = hex(num)[2:]
        num_str = '0' * (8 - len(num_hex)) + num_hex + '\n'
        f.write(num_str)
