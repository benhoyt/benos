�]�0���x <��rj�6��
�� ����  �6�2���.rJ��3��6��� ���ع���	�.r+���	���6��� ,A<#�Dw������&�Xr�z� �L�!QVW���ǀ �� � W��� ^3Ɋ.� �<t'< t�<	t��H��<t< t<	t����D� A���D� A��_^Y�SQRVU3�<-uMF3Ɋ�3۬
�t�$ <9v,,0P�����X2�����t�ۋ�]^ZY[�<ar<zw, �P3ɬA
�u�+�IX�PSQR����ֻ �@�!ZY[X�R�ִ=�!Z�R�ִ?�!Z�OSCopy - Copies a file to absolute sectors on a specified drive
Coded by Benjamin Hoyt in November 1997

 Usage: OSCopy filename starting-sector# destination-drive-letter
Eg:    OSCopy bootsect.bin 0 a:
 Error reading file!
 Bad drive letter!
 Error writing sectors to drive!
 Success...
 