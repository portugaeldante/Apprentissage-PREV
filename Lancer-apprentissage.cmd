@echo off
chcp 65001 >nul
title VHP - Apprendre la prevention
echo.
echo   Lancement de l'apprentissage VHP...
echo   (Le navigateur va s'ouvrir sur http://localhost:8770 - la progression y est sauvegardee.)
echo   Laissez cette fenetre OUVERTE pendant l'utilisation. Fermez-la pour arreter.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0serve.ps1"
