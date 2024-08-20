#!/usr/bin/env python3

# (c)2024 Deri Taufan
# Python script to simplify running terraform plan, apply and destroy during my terraform learning process

import sys
import subprocess

num_arg = len(sys.argv)
#print(num_arg, sys.argv)
if num_arg > 2:
	print("---")
	print("The Python Terraform Plan script can only except one argument after the script. Please try again!")
	print("For example: ./terraform_plan.py ./terraform_source_folder/")
	print("---")
	sys.exit()
elif num_arg == 1:
	print('---')
	print("Please supply the script with the path to Terraform file folder.")
	print("For example: ./terraform_plan.py ./terraform_source_folder/")
	print('---')
	sys.exit()


subprocess.call(['terraform', '-chdir=' + sys.argv[1], 'init'])
subprocess.call(['terraform', '-chdir=' + sys.argv[1], 'get'])
subprocess.call(['terraform', '-chdir=' + sys.argv[1], 'plan'])