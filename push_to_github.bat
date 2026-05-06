@echo off
echo Preparing to push your LivKit App to GitHub...
cd /d C:\Users\Hp\LivKit\App
git remote remove origin
git remote add origin https://github.com/livkit346-commits/livkit-app.git
git branch -M main
echo.
echo A GitHub Login Window will now appear. Please log in!
echo.
git push -u origin main --force
echo.
echo Push Complete! You can now close this window and deploy on CodeMagic.
pause
